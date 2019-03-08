//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaEvents: NSObject {
    
    typealias Submitter = (InstanaEvent) -> Void
    typealias Loader = (URLRequest, Bool, @escaping (InstanaNetworking.Result) -> Void) -> Void
    
    @objc public enum SuspendReporting: Int {
        case never, lowBattery, cellularConnection, lowBatteryAndCellularConnection
    }
    @objc public var suspendReporting: SuspendReporting = .never
    private var timer: Timer?
    private let transmissionDelay: Instana.Types.Seconds = 1
    private let transmissionLowBatteryDelay: TimeInterval = 10
    private let queue = DispatchQueue(label: "com.instana.events")
    private let load: Loader
    private lazy var buffer = { InstanaRingBuffer<InstanaEvent>(size: bufferSize) }()
    @objc var bufferSize = InstanaConfiguration.Defaults.eventsBufferSize {
        didSet {
            queue.sync {
                sendBufferEvents()
                buffer = InstanaRingBuffer(size: bufferSize)
            }
        }
    }
    
    init(load: @escaping Loader = InstanaNetworking().load(request:restricted:completion:)) {
        self.load = load
        super.init()
    }
    
    @objc(submitEvent:)
    public func submit(event: InstanaEvent) {
        queue.async {
            if let overwritten = self.buffer.write(event), let notifiableEvent = overwritten as? InstanaEventResultNotifiable {
                notifiableEvent.completion(.failure(error: InstanaError(code: .bufferOverwrite, description: "Event overwrite casued by buffer size limit.")))
            }
            self.startSendEventsTimer(delay: self.transmissionDelay)
        }
    }
}

private extension InstanaEvents {
    func sendBufferEvents() {
        self.timer?.invalidate()
        self.timer = nil
        
        if Instana.battery.safeForNetworking == false, [.lowBattery, .lowBatteryAndCellularConnection].contains(suspendReporting) {
            startSendEventsTimer(delay: transmissionLowBatteryDelay)
            return
        }
        
        let events = self.buffer.readAll()
        guard events.count > 0 else { return }
        send(events: events)
    }
    
    func startSendEventsTimer(delay: TimeInterval) {
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
        let restrictLoad = [.cellularConnection, .lowBatteryAndCellularConnection].contains(suspendReporting)
        load(request, restrictLoad) { result in
            // TODO: failed requests handling, after prototype
            switch result {
            case .failure(let error):
                self.complete(events, with: .failure(error: error))
            case .success(200...299):
                self.complete(events, with: .success)
            case .success(let statusCode):
                self.complete(events, with: .failure(error: InstanaError(code: .invalidResponse, description: "Invalid repsonse status code: \(statusCode)")))
            }
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
