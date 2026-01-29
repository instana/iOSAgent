//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import Gzip

/// Reporter to queue and submit the Beacons
public class Reporter {
    typealias Completion = (BeaconResult) -> Void
    var completionHandler = [Completion]()
    let queue: InstanaPersistableQueue<CoreBeacon>
    private let dispatchQueue = DispatchQueue(label: "com.instana.ios.agent.reporter", qos: .utility)
    internal var sendFirstBeacon = true // first beacon is sent all by itself, not in a batch
    private var slowSendStartTime: Date?
    private var inSlowModeBeforeFlush = false
    internal var lastFlushStartTime: Double?
    internal var flusher: BeaconFlusher?
    internal var send: BeaconFlusher.Sender?
    private let rateLimiter: ReporterRateLimiter
    private let batterySafeForNetworking: () -> Bool
    private let networkUtility: NetworkUtility
    private var suspendReporting: Set<InstanaConfiguration.SuspendReporting> { session.configuration.suspendReporting }
    private let session: InstanaSession
    private var flushDebounce: TimeInterval {
        batterySafeForNetworking() ? session.configuration.reporterSendDebounce : session.configuration.reporterSendLowBatteryDebounce
    }

    // Prequeue handling
    private(set) var preQueue = [Beacon]()
    private let started = Date().timeIntervalSince1970
    private var mustUsePrequeue: Bool { (Date().timeIntervalSince1970 - started) < session.configuration.preQueueUsageTime }

    private let dropBeaconHandler = DropBeaconHandler()

    // MARK: Init

    init(_ session: InstanaSession,
         batterySafeForNetworking: @escaping () -> Bool = { InstanaSystemUtils.battery.safeForNetworking },
         networkUtility: NetworkUtility = NetworkUtility.shared,
         rateLimiter: ReporterRateLimiter? = nil,
         queue: InstanaPersistableQueue<CoreBeacon>? = nil,
         send: BeaconFlusher.Sender? = nil) {
        self.networkUtility = networkUtility
        self.session = session
        self.send = send
        self.batterySafeForNetworking = batterySafeForNetworking
        self.rateLimiter = rateLimiter ?? ReporterRateLimiter(configs: session.configuration.reporterRateLimits)
        self.queue = queue ?? InstanaPersistableQueue<CoreBeacon>(identifier: "com.instana.ios.mainqueue", maxItems: session.configuration.maxQueueSize)
        purgeOldBeacons(session.configuration.deleteOldBeacons)
        networkUtility.connectionUpdateHandler = { [weak self] connectionType in
            guard let self = self else { return }
            self.updateNetworkConnection(connectionType)
        }
        InstanaApplicationStateHandler.shared.listen { [weak self] state, _ in
            guard let self = self else { return }
            if state == .background, !ProcessInfo.isRunningTests {
                self.runBackgroundFlush()
            }
        }
        dispatchQueue.asyncAfter(deadline: .now() + session.configuration.preQueueUsageTime, execute: emptyPreQueueIfNeeded)
    }

    func purgeOldBeacons(_ deleteOldBeacons: Bool, minutes: Double = 15.0) {
        if !deleteOldBeacons {
            return
        }
        let cutoffTime = Date().millisecondsSince1970 - Int64(minutes * 60.0 * 1000.0)
        var updatedBeacons: Set<CoreBeacon> = []
        for coreBeacon in queue.items {
            if let timestamp = Int64(coreBeacon.ti), timestamp > cutoffTime {
                updatedBeacons.insert(coreBeacon)
            }
        }
        queue.items = updatedBeacons
    }

    func submit(_ beacon: Beacon, _ completion: ((Bool) -> Void)? = nil) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.collectionEnabled else {
                self.session.logger.add("Instana instrumentation is disabled. Beacon might be discarded", level: .warning)
                completion?(false)
                return
            }
            guard self.rateLimiter.canSubmit(beacon) else {
                if self.session.dropBeaconReporting {
                    self.dropBeaconHandler.addBeaconToDropHandler(beacon: beacon)
                }
                self.session.logger.add("Rate Limit reached - Beacon might be discarded", level: .warning)
                completion?(false)
                return
            }
            if self.mustUsePrequeue {
                self.preQueue.append(beacon)
                completion?(true)
                return
            }

            guard !self.queue.isFull else {
                self.session.logger.add("Queue is full - Beacon might be discarded", level: .warning)
                completion?(false)
                return
            }

            if self.session.dropBeaconReporting {
                let mergedDroppedBeacon = self.dropBeaconHandler.mergeDroppedBeacons()
                if mergedDroppedBeacon != nil,
                    let mdCoreBeacon = try? CoreBeaconFactory(self.session).map(mergedDroppedBeacon!) {
                    self.queue.add(mdCoreBeacon)
                }
            }

            let start = Date()
            if let coreBeacon = try? CoreBeaconFactory(self.session).map(beacon) {
                self.queue.add(coreBeacon)
                let passed = Date().timeIntervalSince(start)
                self.session.logger.add("\(Date().millisecondsSince1970) Creating the CoreBeacon took \(passed * 1000) ms")
                self.scheduleFlush()
            }
            completion?(true)
        }
    }

    private func updateNetworkConnection(_ connectionType: NetworkUtility.ConnectionType) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            if connectionType != .none {
                self.scheduleFlush()
            }
        }
    }

    private func emptyPreQueueIfNeeded() {
        if preQueue.isEmpty {
            return
        }
        let coreBeacons = preQueue.compactMap { try? CoreBeaconFactory(self.session).map($0) }
        coreBeacons.forEach { queue.add($0) }
        preQueue.removeAll()
        scheduleFlush()
    }

    internal var isInSlowSendMode: Bool {
        session.configuration.slowSendInterval > 0 && (sendFirstBeacon || slowSendStartTime != nil)
    }

    internal func setSlowSendStartTime(_ time: Date?) {
        if time == nil {
            if slowSendStartTime != nil {
                session.logger.add("Slow send ended at \(String(describing: Date()))")
                slowSendStartTime = nil
            }
        } else if slowSendStartTime == nil {
            // if slow send started, do not update so as to keep the earliest time
            slowSendStartTime = time
            session.logger.add("Slow send started at \(String(describing: time!))")
        }
    }

    func deviceAllowFlush() -> Bool {
        // Check network and battery condition
        var error: Error?
        let connectionType = networkUtility.connectionType
        if connectionType == .none || connectionType == .undetermined {
            error = InstanaError.offline
        } else if suspendReporting.contains(.cellularConnection), connectionType == .cellular {
            error = InstanaError.noWifiAvailable
        } else if suspendReporting.contains(.lowBattery), !batterySafeForNetworking() {
            error = InstanaError.lowBattery
        }
        if error != nil {
            session.logger.add("Cannot send beacon: \(error!)", level: .warning)
            completionHandler.forEach { $0(BeaconResult.failure(error!)) }
            return false
        }
        return true
    }

    func canScheduleFlush() -> Bool {
        if !deviceAllowFlush() {
            return false
        }

        if flusher == nil {
            return true
        }
        if lastFlushStartTime == nil {
            return true
        }

        let maxFlushingTimeAllowed = session.configuration.timeoutInterval + 100.0 // in seconds

        let diff = Date().timeIntervalSince1970 - lastFlushStartTime!
        if diff > maxFlushingTimeAllowed {
            // Previous flushing takes too long, force a new flush to prevent
            // too many beacons accumulated locally thus lead to beacon loss.
            session.logger.add("Previous flushing takes more than \(diff) seconds. Force another flushing now")
            return true
        }
        return false
    }

    func scheduleFlush() {
        guard !queue.items.isEmpty else { return }

        if !canScheduleFlush() { return }

        let start = Date()
        var debounce: TimeInterval
        var beacons: Set<CoreBeacon> = Set([])
        inSlowModeBeforeFlush = isInSlowSendMode
        if inSlowModeBeforeFlush {
            if sendFirstBeacon {
                debounce = flushDebounce
                sendFirstBeacon = false
            } else {
                debounce = session.configuration.slowSendInterval
            }
            var beacon = queue.items.first!
            beacon.updateMetaDataWithSlowSendStartTime(slowSendStartTime)
            beacons.insert(beacon)
        } else {
            debounce = calcDebounceTime()
            beacons = queue.items
        }

        let flusher = BeaconFlusher(reporter: self, items: beacons, debounce: debounce,
                                    config: session.configuration, queue: dispatchQueue,
                                    send: send) { [weak self] result in
            guard let self = self else { return }
            self.dispatchQueue.async { [weak self] in
                let originalBeacons: Set<CoreBeacon>? = (result.sentBeacons.count < beacons.count) ? beacons : nil
                self?.handle(flushResult: result, start, originalBeacons: originalBeacons)
            }
        }
        flusher.schedule()
        self.flusher = flusher
        lastFlushStartTime = Date().timeIntervalSince1970 + debounce
    }

    internal func calcDebounceTime() -> TimeInterval {
        var debounce: TimeInterval = flushDebounce
        let itemsCount = queue.items.count
        if itemsCount >= (queue.maxItems * 4 / 5) {
            // if queue 80% full then flush immediately
            debounce = 0
        } else if itemsCount >= (queue.maxItems / 2) {
            // if queue 50% full then flush quicker than default waiting time
            debounce /= 2.0
        }
        return debounce
    }

    func runBackgroundFlush() {
        #if os(tvOS) || os(watchOS) || os(iOS)
            ProcessInfo.processInfo.performExpiringActivity(withReason: "BackgroundFlush") { expired in
                guard !expired else { return }
                self.dispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.scheduleFlush()
                }
            }
        #endif
    }

    private func handle(flushResult: BeaconFlusher.Result,
                        _ start: Date = Date(),
                        originalBeacons: Set<CoreBeacon>? = nil) {
        let result: BeaconResult
        let errors = flushResult.errors
        let sent = flushResult.sentBeacons
        let end = Date().timeIntervalSince(start)
        errors.forEach { error in
            session.logger.add("Failed to send Beacon batch: \(error)", level: .warning)
        }
        if errors.isEmpty {
            result = BeaconResult.success
            session.logger.add("Did successfully send all beacons in \(end * 1000) ms")
        } else {
            let error = errors.count == 1 ? errors.first! : InstanaError.multiple(errors)
            result = BeaconResult.failure(error)
            session.logger.add("Failed to send beacons in \(end * 1000) ms")
        }

        if originalBeacons == nil {
            // All beacons were successfully sent. Remove them from local file.
            queue.remove(sent) { [weak self] _ in
                self?.completionHandler.forEach { $0(result) }
            }
        } else {
            // For beacons failed sending, increase retry count and save back to file.
            queue.items.subtract(sent)
            var updatedBeacons: Set<CoreBeacon> = []
            for var cBeacon in queue.items {
                if originalBeacons!.contains(cBeacon) {
                    cBeacon.increaseRetryCount()
                    if cBeacon.rct! < session.configuration.maxBeaconResendTries {
                        updatedBeacons.insert(cBeacon)
                    } // else: throw away the beacon
                } else {
                    // new beacons, keep as is
                    updatedBeacons.insert(cBeacon)
                }
            }
            queue.items = updatedBeacons
            queue.write { [weak self] _ in
                self?.completionHandler.forEach { $0(result) }
            }
        }

        flusher = nil // mark this round flush done
        lastFlushStartTime = nil
        if inSlowModeBeforeFlush {
            // Another flush either resend 1 beacon (still in slow mode currently)
            // or flush remaining beacons (got out of slow send mode already)
            var msg: String
            if isInSlowSendMode {
                msg = "schedule flush to send 1 beacon in slow send mode"
            } else {
                msg = "flush all beacons after out of slow send mode"
            }
            session.logger.add(msg)
        }
        // schedule next round flush
        scheduleFlush()
    }
}
