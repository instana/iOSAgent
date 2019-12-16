
import Foundation
import Gzip

/// Reporter to queue and submit the Beacons
public class Reporter {
    
    typealias Submitter = (Beacon) -> Void
    typealias NetworkLoader = (URLRequest, @escaping (InstanaNetworking.Result) -> Void) -> Void
    var completion: (BeaconResult) -> Void = {_ in}
    let queue = InstanaPersistableQueue<CoreBeacon>()
    private let backgroundQueue = DispatchQueue(label: "com.instana.ios.app.background", qos: .background)
    private let send: NetworkLoader
    private let batterySafeForNetworking: () -> Bool
    private let networkUtility: NetworkUtility
    private var suspendReporting: Set<InstanaConfiguration.SuspendReporting> { configuration.suspendReporting }
    private let configuration: InstanaConfiguration
    private var flushWorkItem: DispatchWorkItem?
    private var flushSemaphore: DispatchSemaphore?

    // MARK: Init
    init(_ configuration: InstanaConfiguration,
         useGzip: Bool = true,
         batterySafeForNetworking: @escaping () -> Bool = { InstanaSystemUtils.battery.safeForNetworking },
         networkUtility: NetworkUtility = NetworkUtility(),
         send: @escaping NetworkLoader = InstanaNetworking().send(request:completion:)) {
        self.networkUtility = networkUtility
        self.configuration = configuration
        self.batterySafeForNetworking = batterySafeForNetworking
        self.send = send
        networkUtility.connectionUpdateHandler = {[weak self] connectionType in
            guard let self = self else { return }
            if connectionType != .none {
                self.scheduleFlush()
            }
        }
    }

    func submit(_ beacon: Beacon, _ completion: (() -> Void)? = nil) {
        backgroundQueue.async(qos: .background) {
            let start = Date()
            guard let coreBeacon = try? CoreBeaconFactory(self.configuration).map(beacon) else { return }
            self.queue.add(coreBeacon)
            let passed = Date().timeIntervalSince(start)
            Instana.current?.logger.add("Creating the CoreBeacon took \(passed*1000) ms")
            completion?()
        }
        scheduleFlush()
    }

    func scheduleFlush() {
        guard !queue.items.isEmpty else { return }
        let workItem = DispatchWorkItem() {[weak self] in
            guard let self = self else { return }
            let start = Date()
            self.flushSemaphore = DispatchSemaphore(value: 0)
            self.flushQueue()
            let passed = Date().timeIntervalSince(start)
            Instana.current?.logger.add("Flushing and writing the queue took \(passed*1000) ms")
             _ = self.flushSemaphore?.wait(timeout: .now() + 20)
            self.flushSemaphore = nil
        }
        flushWorkItem?.cancel()
        flushWorkItem = workItem
        let interval = batterySafeForNetworking() ? configuration.transmissionDelay : configuration.transmissionLowBatteryDelay
        backgroundQueue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    func flushQueue() {
        let connectionType = networkUtility.connectionType
        guard connectionType != .none else {
            complete([], .failure(InstanaError(code: .offline, description: "No connection available")))
            return
        }
        if suspendReporting.contains(.cellularConnection) && connectionType == .cellular {
            complete([], .failure(InstanaError(code: .noWifiAvailable, description: "No WIFI Available")))
            return
        }
        if suspendReporting.contains(.lowBattery) && !batterySafeForNetworking() {
            complete([], .failure(InstanaError(code: .lowBattery, description: "Battery too low for flushing")))
            return
        }

        let beacons = queue.items
        let request: URLRequest
        do {
            request = try createBatchRequest(from: beacons)
        } catch {
            complete([], .failure(error))
            return
        }
        send(request) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.complete(beacons, .failure(error))
            case .success(200...299):
                self.complete(beacons, .success)
            case .success(let statusCode):
                self.complete(beacons, .failure(InstanaError(code: .invalidResponse, description: "Invalid repsonse status code: \(statusCode)")))
            }
        }
    }
    
    func complete(_ beacons: [CoreBeacon],_ result: BeaconResult) {
        switch result {
        case .success:
            Instana.current?.logger.add("Did send beacons \(beacons)")
            queue.remove(beacons) {[weak self] _ in
                guard let self = self else { return }
                self.completion(result)
            }
        case .failure(let error):
            Instana.current?.logger.add("Failed to send Beacon batch: \(error)", level: .warning)
            completion(result)
        }
        flushSemaphore?.signal()
    }
}

extension Reporter {

    func createBatchRequest(from beacons: [CoreBeacon]) throws -> URLRequest {
        guard !configuration.key.isEmpty else {
            throw InstanaError(code: .notAuthenticated, description: "Missing application key. No data will be sent.")
        }

        var urlRequest = URLRequest(url: configuration.reportingURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("text/plain", forHTTPHeaderField: "Content-Type")

        let data = beacons.asString.data(using: .utf8)

        if configuration.gzipReport, let gzippedData = try? data?.gzipped(level: .bestCompression) {
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
