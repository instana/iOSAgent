//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaEvents: NSObject {
    @objc public enum SuspendReporting: Int {
        case never, lowBatery, cellularConnection, lowBatteryAndCellularConnection
    }
    @objc public var suspendReporting: SuspendReporting = .never // TODO: handle
    private var timer: Timer?
    private let delay: TimeInterval = 1
    private let queue = DispatchQueue(label: "com.instana.events")
    private let session = URLSession(configuration: .default)
    private var buffer = InstanaRingBuffer<InstanaEvent>(size: 200)
    @objc var bufferSize = 200 {
        didSet {
            queue.sync {
                sendBufferEvents()
                buffer = InstanaRingBuffer(size: bufferSize)
            }
        }
    }
    
    @objc(submitEvent:)
    public func submit(event: InstanaEvent) {
        // TODO: invoke callback of overwritten event
        
        queue.async {
            self.buffer.write(event)
            self.startSendEventsTimer()
        }
    }
}

private extension InstanaEvents {
    func sendBufferEvents() {
        self.timer?.invalidate()
        self.timer = nil
        let events = self.buffer.readAll()
        // TODO: do we discard events while suspension is on?
        guard events.count > 0 else { return }
        send(events: events)
    }
    
    func startSendEventsTimer() {
        guard timer == nil || timer?.isValid == false else { return }
        let t = Timer(timeInterval: delay, target: self, selector: #selector(onSendEventsTimer), userInfo: nil, repeats: false)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    
    @objc func onSendEventsTimer() {
        queue.async { self.sendBufferEvents() }
    }
}

private extension InstanaEvents {
    func send(events: [InstanaEvent]) {
        let request: URLRequest
        do {
            request = try batchRequest(for: events)
        }
        catch {
            Instana.log.add(error.localizedDescription)
            invokeCallback(for: events, result: .failure(error: error))
            return
        }
        session.dataTask(with: request) { (data, response, error) in
            self.handle(response: response, error: error, for: events)
        }.resume()
    }
    
    func batchRequest(for events: [InstanaEvent]) throws -> URLRequest {
        guard var url = URL(string: Instana.reportingUrl) else {
            throw InstanaError(code: .invalidRequest, description: "Invalid reporting url. No data will be sent.")
        }
        guard let key = Instana.key else {
            throw InstanaError(code: .notAuthenticated, description: "Missing application key. No data will be sent.")
        }
        url.appendPathComponent("v1/api/\(key)/batch")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEvents = events.compactMap { $0.toJSON() }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonEvents) else {
            throw InstanaError(code: .invalidRequest, description: "Could not serialize events data.")
        }
        
        if let gzippedData = try? (jsonData as NSData).gzipped(withCompressionLevel: -1) { // -1 default compression level
            urlRequest.httpBody = gzippedData
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.setValue("\(gzippedData.count)", forHTTPHeaderField: "Content-Length")
        }
        else {
            urlRequest.httpBody = jsonData
        }

        return urlRequest
    }
    
    func invokeCallback(for events: [InstanaEvent], result: InstanaEventResult) {
        events.forEach { event in
            if let notifiableEvent = event as? InstanaEventResultNotifiable {
                notifiableEvent.completion(result);
            }
        }
        switch result {
        case .success: Instana.log.add("Event batch sent.")
        case .failure(let error): Instana.log.add("Failed to send event batch: \(error)", level: .warning)
        }
    }
    
    func handle(response: URLResponse?, error: Error?, for events: [InstanaEvent]) {
        // TODO: failed requests handling, after prototype
        if let error = error {
            self.invokeCallback(for: events, result: .failure(error: error))
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            self.invokeCallback(for: events, result: .failure(error: InstanaError(code: .invalidResponse, description: "Can't parse server response.")))
            return
        }
        switch httpResponse.statusCode {
        case 200...299:
            self.invokeCallback(for: events, result: .success)
        default:
            self.invokeCallback(for: events, result: .failure(error: InstanaError(code: .invalidResponse, description: String(describing: httpResponse))))
        }
    }
}
