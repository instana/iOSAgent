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
    private var flusher: BeaconFlusher?
    private let send: BeaconFlusher.Sender?
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
        networkUtility.connectionUpdateHandler = { [weak self] connectionType in
            guard let self = self else { return }
            self.updateNetworkConnection(connectionType)
        }
        InstanaApplicationStateHandler.shared.listen { [weak self] state in
            guard let self = self else { return }
            if state == .background, !ProcessInfo.isRunningTests {
                self.runBackgroundFlush()
            }
        }
        dispatchQueue.asyncAfter(deadline: .now() + session.configuration.preQueueUsageTime, execute: emptyPreQueueIfNeeded)
    }

    func submit(_ beacon: Beacon, _ completion: ((Bool) -> Void)? = nil) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.collectionEnabled else {
                self.session.logger.add("Instana instrumentation is disabled. Beacon might be discarded", level: .warning)
                completion?(false)
                return
            }
            guard self.rateLimiter.canSubmit() else {
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

    func scheduleFlush() {
        guard !queue.items.isEmpty else { return }
        let start = Date()
        let debounce = queue.isFull ? 0.0 : flushDebounce
        let connectionType = networkUtility.connectionType
        guard connectionType != .none else {
            return handle(flushResult: .failure([InstanaError.offline]))
        }
        if suspendReporting.contains(.cellularConnection), connectionType == .cellular {
            return handle(flushResult: .failure([InstanaError.noWifiAvailable]))
        }
        if suspendReporting.contains(.lowBattery), !batterySafeForNetworking() {
            return handle(flushResult: .failure([InstanaError.lowBattery]))
        }
        let flusher = BeaconFlusher(items: queue.items, debounce: debounce, config: session.configuration, queue: dispatchQueue, send: send) { [weak self] result in
            guard let self = self else { return }
            self.handle(flushResult: result, start)
        }
        flusher.schedule()
        self.flusher = flusher
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

    private func handle(flushResult: BeaconFlusher.Result, _ start: Date = Date()) {
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
        queue.remove(sent) { [weak self] _ in
            guard let self = self else { return }
            self.completionHandler.forEach { $0(result) }
        }
    }
}
