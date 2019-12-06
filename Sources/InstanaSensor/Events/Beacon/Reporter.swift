
import Foundation
import Gzip

/// Reporter to manager and send out the events
public class Reporter: NSObject {
    
    typealias Submitter = (Event) -> Void
    typealias NetworkLoader = (URLRequest, @escaping (InstanaNetworking.Result) -> Void) -> Void
    var completion: (EventResult) -> Void = {_ in}
    private var backgroundQueue = DispatchQueue(label: "com.instana.ios.app.background", qos: .background, attributes: .concurrent)
    private var timer: Timer?
    private let send: NetworkLoader
    private let batterySafeForNetworking: () -> Bool
    private let hasWifi: () -> Bool
    private var suspendReporting: Set<InstanaConfiguration.SuspendReporting> { configuration.suspendReporting }
    private (set) var queue = [Event]()

    private let configuration: InstanaConfiguration

    // MARK: Init
    init(_ configuration: InstanaConfiguration,
         useGzip: Bool = true,
         batterySafeForNetworking: @escaping () -> Bool = { InstanaSystemUtils.battery.safeForNetworking },
         hasWifi: @escaping () -> Bool = { Instana.current.monitors.network.connectionType == .wifi },
         send: @escaping NetworkLoader = InstanaNetworking().send(request:completion:)) {
        self.configuration = configuration
        self.batterySafeForNetworking = batterySafeForNetworking
        self.hasWifi = hasWifi
        self.send = send
        super.init()
    }

    deinit {
        timer?.invalidate()
    }

    func submit(_ event: Event) {
        // TODO: Build OperationQueue later - send all directly now
        // TODO: Queue should also persist the events in case of a crash or network failure
        queue.append(event)
        scheduleFlush()
    }

    func scheduleFlush() {
        timer?.invalidate()
        let interval = batterySafeForNetworking() ? configuration.transmissionDelay : configuration.transmissionLowBatteryDelay
        if interval == 0.0 {
            flushQueue()
            return // No timer needed - flush directly
        }
        let t = InstanaTimerProxy.timer(proxied: self, timeInterval: interval, userInfo: CFAbsoluteTimeGetCurrent(), repeats: false)
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }
}

extension Reporter: InstanaTimerProxiedTarget {
    func onTimer(timer: Timer) {
        flushQueue()
    }
}

extension Reporter {
    // TODO: Test Flush
    // TODO: Consider flushing in a background thread
    func flushQueue() {
        backgroundQueue.async {
            self._flushQueue()
        }
    }

    private func _flushQueue() {
        if suspendReporting.contains(.cellularConnection) && !hasWifi() {
            complete([], .failure(InstanaError(code: .noWifiAvailable, description: "No WIFI Available")))
            return
        }
        if suspendReporting.contains(.lowBattery) && !batterySafeForNetworking() {
            complete([], .failure(InstanaError(code: .lowBattery, description: "Battery too low for flushing")))
            return
        }

        let eventsToSend = queue
        let request: URLRequest
        var beacons = [CoreBeacon]()
        do {
            beacons = try BeaconEventMapper(configuration).map(eventsToSend)
            request = try createBatchRequest(from: beacons)
        } catch {
            complete(beacons, .failure(error))
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
    
    func complete(_ beacons: [CoreBeacon],_ result: EventResult) {
        switch result {
        case .success:
            Instana.current.logger.add("Did send beacons \(beacons)")
            removeFromQueue(beacons)
        case .failure(let error):
            Instana.current.logger.add("Failed to send Beacon batch: \(error)", level: .warning)
        }
        completion(result)
    }

    func removeFromQueue(_ beacons: [CoreBeacon]) {
        beacons.forEach { beacon in
            queue.removeAll(where: {$0.id == beacon.bid})
        }
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
