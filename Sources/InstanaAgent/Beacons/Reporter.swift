//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import Gzip

/// Reporter to queue and submit the Beacons
public class Reporter {
    typealias Submitter = (Beacon) -> Void
    typealias Completion = (BeaconResult) -> Void
    typealias NetworkLoader = (URLRequest, @escaping (InstanaNetworking.Result) -> Void) -> Void
    var completionHandler = [Completion]()
    let queue: InstanaPersistableQueue<CoreBeacon>
    private let dispatchQueue = DispatchQueue(label: "com.instana.ios.agent.reporter", qos: .utility)
    private let send: NetworkLoader
    private let rateLimiter: ReporterRateLimiter
    private let batterySafeForNetworking: () -> Bool
    private let networkUtility: NetworkUtility
    private var suspendReporting: Set<InstanaConfiguration.SuspendReporting> { session.configuration.suspendReporting }
    private let session: InstanaSession
    private var flushWorkItem: DispatchWorkItem?

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

    func submit(_ beacon: Beacon, _ completion: (() -> Void)? = nil) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.collectionEnabled else {
                self.session.logger.add("Instana instrumentation is disabled. Beacon will be discarded", level: .warning)
                completion?()
                return
            }
            guard self.rateLimiter.canSubmit() else {
                self.session.logger.add("Rate Limit reached - Beacon will be discarded", level: .warning)
                completion?()
                return
            }
            if self.mustUsePrequeue {
                self.preQueue.append(beacon)
                completion?()
                return
            }

            guard !self.queue.isFull else {
                self.session.logger.add("Queue is full - Beacon will be discarded", level: .warning)
                completion?()
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

    private func scheduleFlush() {
        guard !queue.items.isEmpty else { return }
        flushWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard let flushWorkItem = self.flushWorkItem, !flushWorkItem.isCancelled else { return }
            self.flushQueue()
        }
        flushWorkItem = workItem
        var interval = batterySafeForNetworking() ? session.configuration.reporterSendDebounce : session.configuration.reporterSendLowBatteryDebounce
        interval = queue.isFull ? 0.0 : interval
        dispatchQueue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    func flushQueue(retry: Int = 0) {
        let connectionType = networkUtility.connectionType
        guard connectionType != .none else {
            return complete(error: InstanaError.offline)
        }
        if suspendReporting.contains(.cellularConnection), connectionType == .cellular {
            return complete(error: InstanaError.noWifiAvailable)
        }
        if suspendReporting.contains(.lowBattery), !batterySafeForNetworking() {
            return complete(error: InstanaError.lowBattery)
        }
        let start = Date()
        let beaconsBatches = Array(queue.items).chunked(size: session.configuration.maxBeaconsPerRequest)
        let disapatchGroup = DispatchGroup()
        var dispatchErrors = [Error]()
        var dispatchedBeacons = [CoreBeacon]()
        beaconsBatches.forEach { beaconBatch in
            disapatchGroup.enter()
            let request: URLRequest
            do {
                request = try createBatchRequest(from: beaconBatch.asString)
            } catch {
                dispatchErrors.append(error)
                disapatchGroup.leave()
                return
            }
            send(request) { sentResult in
                switch sentResult {
                case .success:
                    dispatchedBeacons.append(contentsOf: beaconBatch)
                case let .failure(error):
                    dispatchErrors.append(error)
                }
                disapatchGroup.leave()
            }
        }
        disapatchGroup.notify(queue: .main) {
            let end = Date().timeIntervalSince(start)
            self.session.logger.add("Flushing and writing the queue took \(end * 1000) ms")
            self.complete(sentBeacons: dispatchedBeacons, errors: dispatchErrors)
            if !dispatchErrors.isEmpty {
                self.retryFlush(last: retry)
            }
        }
    }

    private func retryFlush(last: Int) {
        guard last < session.configuration.maxRetries else {
            return
        }
        let next = last + 1
        runExponentialBackoffRetry(on: dispatchQueue, retry: next) {[weak self] in
            guard let self = self else { return }
            self.flushQueue(retry: next)
        }
    }

    private func runBackgroundFlush() {
        #if os(tvOS) || os(watchOS) || os(iOS)
            ProcessInfo.processInfo.performExpiringActivity(withReason: "BackgroundFlush") { expired in
                guard !expired else { return }
                self.dispatchQueue.async { [weak self] in
                    guard let self = self else { return }
                    guard !self.queue.items.isEmpty else { return }
                    self.flushQueue()
                }
            }
        #endif
    }

    private func complete(error: Error) {
        complete(sentBeacons: [], errors: [error])
    }

    private func complete(sentBeacons: [CoreBeacon], errors: [Error]) {
        errors.forEach { error in
            session.logger.add("Failed to send Beacon batch: \(error)", level: .warning)
        }
        let result: BeaconResult
        if errors.isEmpty {
            result = BeaconResult.success
            session.logger.add("Did successfully send all beacons")
        } else {
            let error = errors.count == 1 ? errors.first! : InstanaError.multiple(errors)
            result = BeaconResult.failure(error)
        }

        queue.remove(sentBeacons) { [weak self] _ in
            guard let self = self else { return }
            self.completionHandler.forEach { $0(result) }
        }
    }

    private func runExponentialBackoffRetry(on queue: DispatchQueue, retry: Int = 1, closure: @escaping () -> Void) {
        let maxDelay = 60 * 5 * 1000
        var delay = Int(pow(2.0, Double(retry))) * 1000
        let jitter = Int.random(in: 0...1000)
        delay = min(delay + jitter, maxDelay)
        queue.asyncAfter(deadline: DispatchTime.now() + .milliseconds(delay), execute: closure)
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
            queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
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
