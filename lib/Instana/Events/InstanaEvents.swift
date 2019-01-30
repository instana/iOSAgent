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
    private lazy var buffer = { InstanaRingBuffer<InstanaEvent>(size: bufferSize) }()
    @objc var bufferSize = InstanaConfiguration.Defaults.eventsBufferSize {
        didSet {
            queue.sync {
                sendBufferEvents()
                buffer = InstanaRingBuffer(size: bufferSize)
            }
        }
    }
    
    @objc(submitEvent:)
    public func submit(event: InstanaEvent) {
        queue.async {
            if let overwritten = self.buffer.write(event), let notifiableEvent = overwritten as? InstanaEventResultNotifiable {
                notifiableEvent.completion(.failure(error: InstanaError(code: .bufferOverwrite, description: "Event overwrite casued by buffer size limit.")))
            }
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
            request = try events.toBatchRequest()
        }
        catch {
            complete(events, with: .failure(error: error))
            return
        }
        session.dataTask(with: request) { (data, response, error) in
            self.handle(response: response, error: error, for: events)
        }.resume()
    }
    
    func handle(response: URLResponse?, error: Error?, for events: [InstanaEvent]) {
        // TODO: failed requests handling, after prototype
        if let error = error {
            complete(events, with: .failure(error: error))
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            complete(events, with: .failure(error: InstanaError(code: .invalidResponse, description: "Can't parse server response.")))
            return
        }
        switch httpResponse.statusCode {
        case 200...299:
            complete(events, with: .success)
        default:
            complete(events, with: .failure(error: InstanaError(code: .invalidResponse, description: String(describing: httpResponse))))
        }
    }
    
    func complete(_ events: [InstanaEvent], with result: InstanaEventResult) {
        events.invokeCallbackIfNeeded(with: result)
        switch result {
        case .success: Instana.log.add("Event batch sent.")
        case .failure(let error): Instana.log.add("Failed to send event batch: \(error)", level: .warning)
        }
    }
}
