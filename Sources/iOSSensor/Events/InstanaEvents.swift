//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Object acting as a namespace for configuring and using events.
@objc public class InstanaEvents: NSObject {
    
    typealias Submitter = (InstanaEvent) -> Void
    typealias Loader = (URLRequest, Bool, @escaping (InstanaNetworking.Result) -> Void) -> Void
    typealias EventsToRequest = ([InstanaEvent]) throws -> URLRequest
    
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
    private lazy var buffer = { InstanaRingBuffer<InstanaEvent>(size: bufferSize) }()
    @objc var bufferSize = InstanaConfiguration.Defaults.eventsBufferSize {
        didSet {
            queue.sync {
                sendBufferEvents()
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
    
    /// Submit an event to the Instana backend.
    ///
    /// Events are stored in a ring buffer and can be overwritten if too many are submited before a buffer flush.
    /// To avoid this, `bufferSize` can be increased in the configuration.
    ///
    /// - Parameter event: For SDK users this should be `InstanaCustomEvent`.
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
        
        if batterySafeForNetworking() == false, [.lowBattery, .lowBatteryOrCellularConnection].contains(suspendReporting) {
            startSendEventsTimer(delay: transmissionLowBatteryDelay)
            return
        }
        
        let events = self.buffer.readAll()
        guard events.count > 0 else { return }
        send(events: events)
    }
    
    func startSendEventsTimer(delay: TimeInterval) {
        guard timer == nil || timer?.isValid == false else { return }
        let t = InstanaTimerProxy.timer(proxied: self, timeInterval: delay)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

extension InstanaEvents: InstanaTimerProxiedTarget {
    func onTimer(timer: Timer) {
        queue.async { self.sendBufferEvents() }
    }
}

private extension InstanaEvents {
    func send(events: [InstanaEvent]) {
        let request: URLRequest
        do {
            request = try eventsToRequest(events)
        }
        catch {
            complete(events, with: .failure(error: error))
            return
        }
        let restrictLoad = [.cellularConnection, .lowBatteryOrCellularConnection].contains(suspendReporting)
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
