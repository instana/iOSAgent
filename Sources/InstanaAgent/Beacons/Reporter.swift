import Foundation
import Gzip
import UIKit

/// Reporter to queue and submit the Beacons
public class Reporter {
    typealias Submitter = (Beacon) -> Void
    typealias Completion = (BeaconResult) -> Void
    typealias NetworkLoader = (URLRequest, @escaping (InstanaNetworking.Result) -> Void) -> Void
    var completionHandler = [Completion]()
    let queue: InstanaPersistableQueue<CoreBeacon>
    private let backgroundQueue = DispatchQueue(label: "com.instana.ios.agent.background", qos: .background)
    private let send: NetworkLoader
    private let rateLimiter: ReporterRateLimiter
    private let batterySafeForNetworking: () -> Bool
    private let networkUtility: NetworkUtility
    private var suspendReporting: Set<InstanaConfiguration.SuspendReporting> { session.configuration.suspendReporting }
    private let session: InstanaSession
    private var flushWorkItem: DispatchWorkItem?
    private var flushSemaphore: DispatchSemaphore?
    private var backgroundTaskID: UIBackgroundTaskIdentifier?

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
         send: @escaping NetworkLoader = InstanaNetworking().send(request:completion:)) {
        self.networkUtility = networkUtility
        self.session = session
        self.batterySafeForNetworking = batterySafeForNetworking
        self.send = send
        self.rateLimiter = rateLimiter ?? ReporterRateLimiter(configs: session.configuration.reporterRateLimits)
        self.queue = queue ?? InstanaPersistableQueue<CoreBeacon>(identifier: "com.instana.ios.mainqueue", maxItems: session.configuration.maxBeaconsPerRequest)
        networkUtility.connectionUpdateHandler = { [weak self] connectionType in
            guard let self = self else { return }
            if connectionType != .none {
                self.scheduleFlush()
            }
        }
        InstanaApplicationStateHandler.shared.listen { [weak self] state in
            guard let self = self else { return }
            if state == .background {
                self.runBackgroundFlush()
            }
        }
        backgroundQueue.asyncAfter(deadline: .now() + session.configuration.preQueueUsageTime, execute: emptyPreQueueIfNeeded)
    }

    func submit(_ beacon: Beacon, _ completion: (() -> Void)? = nil) {
        guard rateLimiter.canSubmit() else {
            self.session.logger.add("Rate Limit reached - Beacon will be discarded", level: .warning)
            completion?()
            return
        }
        if mustUsePrequeue {
            backgroundQueue.sync {
                self.preQueue.append(beacon)
            }
            completion?()
            return
        }
        backgroundQueue.async(qos: .background) {
            guard !self.queue.isFull else {
                self.session.logger.add("Queue is full - Beacon will be discarded", level: .warning)
                return
            }
            let start = Date()
            if let coreBeacon = try? CoreBeaconFactory(self.session).map(beacon) {
                self.queue.add(coreBeacon)
                let passed = Date().timeIntervalSince(start)
                self.session.logger.add("\(Date().millisecondsSince1970) Creating the CoreBeacon took \(passed * 1000) ms")
                self.scheduleFlush()
            }
            completion?()
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
        flushWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard let flushWorkItem = self.flushWorkItem, !flushWorkItem.isCancelled else { return }
            let start = Date()
            self.flushSemaphore = DispatchSemaphore(value: 0)
            self.flushQueue()
            let passed = Date().timeIntervalSince(start)
            self.session.logger.add("Flushing and writing the queue took \(passed * 1000) ms")
            _ = self.flushSemaphore?.wait(timeout: .now() + 20)
            self.flushSemaphore = nil
        }
        flushWorkItem = workItem
        var interval = batterySafeForNetworking() ? session.configuration.transmissionDelay : session.configuration.transmissionLowBatteryDelay
        interval = queue.isFull ? 0.0 : interval
        backgroundQueue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    func flushQueue() {
        let connectionType = networkUtility.connectionType
        guard connectionType != .none else {
            return complete([], .failure(InstanaError.offline))
        }
        if suspendReporting.contains(.cellularConnection), connectionType == .cellular {
            return complete([], .failure(InstanaError.noWifiAvailable))
        }
        if suspendReporting.contains(.lowBattery), !batterySafeForNetworking() {
            return complete([], .failure(InstanaError.lowBattery))
        }

        let beacons = Array(queue.items)
        let beaconsAsString = beacons.asString
        let request: URLRequest
        do {
            request = try createBatchRequest(from: beaconsAsString)
        } catch {
            complete([], .failure(error))
            return
        }
        send(request) { [weak self] result in
            guard let self = self else { return }
            self.session.logger.add("Did transfer beacon\n \(beaconsAsString)")
            switch result {
            case let .failure(error):
                self.complete(beacons, .failure(error))
            case .success:
                self.complete(beacons, .success)
            }
        }
    }

    func runBackgroundFlush() {
        guard !queue.items.isEmpty else { return }
        ProcessInfo.processInfo.performExpiringActivity(withReason: "BackgroundFlush") { expired in
            guard !expired else { return }
            self.flushQueue()
        }
    }

    func complete(_ beacons: [CoreBeacon], _ result: BeaconResult) {
        let beaconsToBeRemoved: [CoreBeacon]
        switch result {
        case .success:
            session.logger.add("Did successfully send beacons")
            beaconsToBeRemoved = beacons
        case let .failure(error):
            session.logger.add("Failed to send Beacon batch: \(error)", level: .warning)
            let removeFromQueue = queue.isFull || (error as? InstanaError).isHTTPClientError
            beaconsToBeRemoved = removeFromQueue ? beacons : []
        }
        queue.remove(beaconsToBeRemoved) { [weak self] _ in
            guard let self = self else { return }
            self.completionHandler.forEach { $0(result) }
            self.flushSemaphore?.signal()
        }
    }
}

extension Reporter {
    func createBatchRequest(from beacons: String) throws -> URLRequest {
        guard !session.configuration.key.isEmpty else {
            throw InstanaError.missingAppKey
        }

        var urlRequest = URLRequest(url: session.configuration.reportingURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("text/plain", forHTTPHeaderField: "Content-Type")

        let data = beacons.data(using: .utf8)

        if session.configuration.gzipReport, let gzippedData = try? data?.gzipped(level: .bestCompression) {
            urlRequest.httpBody = gzippedData
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.setValue("\(gzippedData.count)", forHTTPHeaderField: "Content-Length")
        } else {
            urlRequest.httpBody = data
            urlRequest.setValue("\(data?.count ?? 0)", forHTTPHeaderField: "Content-Length")
        }

        return urlRequest
    }
}

class ReporterRateLimiter {
    class Limiter {
        let maxItems: Int
        let timeout: TimeInterval
        var current = 0
        private lazy var queue = DispatchQueue(label: "com.instana.ios.agent.reporterratelimit.\(maxItems).\(timeout)")

        var exceeds: Bool { current > maxItems }

        init(maxItems: Int, timeout: TimeInterval) {
            self.maxItems = maxItems
            self.timeout = timeout
            scheduleReset()
        }

        func scheduleReset() {
            queue.asyncAfter(deadline: .now() + timeout) {[weak self] in
                guard let self = self else { return }
                self.current = 0
                self.scheduleReset()
            }
        }

        func signal() -> Bool {
            queue.sync {
                current += 1
                return exceeds
            }
        }
    }

    let limiters: [Limiter]

    init(configs: [InstanaConfiguration.ReporterRateLimitConfig]) {
        limiters = configs.map { Limiter(maxItems: $0.maxItems, timeout: $0.timeout) }
    }

    func canSubmit() -> Bool {
        limiters.map { $0.signal() }.filter { $0 == true }.isEmpty
    }
}
