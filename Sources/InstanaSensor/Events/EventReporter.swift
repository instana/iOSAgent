//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Reporter to manager and send out the events
@objc public class EventReporter: NSObject {
    
    typealias Submitter = (Event) -> Void
    typealias Loader = (URLRequest, Bool, @escaping (InstanaNetworking.Result) -> Void) -> Void
    typealias EventsToRequest = ([Event]) throws -> URLRequest
    
    /// An enum insted of option list because of Obj-C support.
    @objc public enum SuspendReporting: Int {
        /// Reporting is never suspended.
        case never
        /// Reporting is suspended while the device battery is low.
        case lowBattery
        /// Reporting is suspended while the device is using a cellular connection.
        case cellularConnection
        /// Reporting is suspended while the device battery is low or the device is using a cellular connection.
        case lowBatteryOrCellularConnection
    }
    /// Determine in which cases to suspend sending of events to the Instana backend.
    @objc public var suspendReporting: SuspendReporting = .never
    private var timer: Timer?
    private let transmissionDelay: Instana.Types.Seconds
    private let transmissionLowBatteryDelay: Instana.Types.Seconds
    private let queue = DispatchQueue(label: "com.instana.events")
    private let eventsToRequest: EventsToRequest
    private let load: Loader
    private let batterySafeForNetworking: () -> Bool
    private lazy var buffer = { InstanaRingBuffer<Event>(size: bufferSize) }()
    @objc var bufferSize = InstanaConfiguration.Defaults.eventsBufferSize {
        didSet {
            queue.sync {
                sendBuffer()
                buffer = InstanaRingBuffer(size: bufferSize)
            }
        }
    }
    
    init(transmissionDelay: Instana.Types.Seconds = 1,
         transmissionLowBatteryDelay: Instana.Types.Seconds = 10,
         eventsToRequest: @escaping EventsToRequest = { try $0.toBatchRequest() },
         batterySafeForNetworking: @escaping () -> Bool = { Instana.battery.safeForNetworking },
         load: @escaping Loader = InstanaNetworking().load(request:restricted:completion:)) {
        self.eventsToRequest = eventsToRequest
        self.transmissionDelay = transmissionDelay
        self.transmissionLowBatteryDelay = transmissionLowBatteryDelay
        self.batterySafeForNetworking = batterySafeForNetworking
        self.load = load
        super.init()
    }
    
    /// Submit a event to the Instana backend.
    ///
    /// Events are stored in a ring buffer and can be overwritten if too many are submited before a buffer flush.
    /// To avoid this, `bufferSize` can be increased in the configuration.
    ///
    /// - Parameter event: For SDK users this should be `CustomEvent`.
    @objc(submitEvent:)
    public func submit(_ event: Event) {
        queue.async {
            if let overwritten = self.buffer.write(event), let notifiableEvent = overwritten as? EventResultNotifiable {
                notifiableEvent.completion(.failure(error: InstanaError(code: .bufferOverwrite, description: "Event overwrite casued by buffer size limit.")))
            }
            self.startSendTimer(delay: self.transmissionDelay)
        }
    }
}

private extension EventReporter {
    func sendBuffer() {
        self.timer?.invalidate()
        self.timer = nil
        
        if batterySafeForNetworking() == false, [.lowBattery, .lowBatteryOrCellularConnection].contains(suspendReporting) {
            startSendTimer(delay: transmissionLowBatteryDelay)
            return
        }
        
        let events = self.buffer.readAll()
        guard events.count > 0 else { return }
        send(events: events)
    }
    
    func startSendTimer(delay: TimeInterval) {
        guard timer == nil || timer?.isValid == false else { return }
        let t = InstanaTimerProxy.timer(proxied: self, timeInterval: delay)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

extension EventReporter: InstanaTimerProxiedTarget {
    func onTimer(timer: Timer) {
        queue.async { self.sendBuffer() }
    }
}

private extension EventReporter {
    func send(events: [Event]) {
        let request: URLRequest
        do {
            request = try eventsToRequest(events)
        }
        catch {
            complete(events, .failure(error: error))
            return
        }
        let restrictLoad = [.cellularConnection, .lowBatteryOrCellularConnection].contains(suspendReporting)
        load(request, restrictLoad) { result in
            // TODO: failed requests handling, after prototype
            switch result {
            case .failure(let error):
                self.complete(events, .failure(error: error))
            case .success(200...299):
                self.complete(events, .success)
            case .success(let statusCode):
                self.complete(events, .failure(error: InstanaError(code: .invalidResponse, description: "Invalid repsonse status code: \(statusCode)")))
            }
        }
    }
    
    func complete(_ events: [Event], _ result: EventResult) {
        events.invokeCallbackIfNeeded(result)
        switch result {
        case .success: Instana.log.add("Event batch sent.")
        case .failure(let error): Instana.log.add("Failed to send Event batch: \(error)", level: .warning)
        }
    }
}
