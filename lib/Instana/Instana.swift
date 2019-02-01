//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class Instana: NSObject {
    @objc public static let alerts = InstanaAlerts()
    @objc public static let events = InstanaEvents()
    @objc public static let crashReporting = InstanaCrashReporting()
    @objc public static let remoteCallInstrumentation = InstanaRemoteCallInstrumentation()
    static let log = InstanaLogger()
    static let battery = InstanaBatteryUtils()

    @objc public static let sessionId = UUID().uuidString
    private(set) static var reportingUrl = InstanaConfiguration.Defaults.reportingUrl
    private(set) static var key: String?
    
    private override init() {}
    
    @objc public static func setup() {
        let defaultPath = Bundle.main.path(forResource: "InstanaConfiguration", ofType: ".plist")
        guard let config = InstanaConfiguration.read(from: defaultPath) else { return }
        setup(with: config)
    }
    
    @objc public static func setup(with configPath: String) {
        guard let config = InstanaConfiguration.read(from: configPath) else { return }
        setup(with: config)
    }
    
    @objc public static func setup(withKey key: String, reportingUrl: String? = nil) {
        let config = InstanaConfiguration.default(key: key, reportingUrl:  reportingUrl)
        setup(with: config)
    }
}

public extension Instana {
    @objc public class Types: NSObject {
        private override init() {}
        public typealias Milliseconds = Double
        public typealias Seconds = Double
        public typealias UTCTimestamp = TimeInterval
    }
}

private extension Instana {    
    static func setup(with config: InstanaConfiguration) {
        key = config.key
        reportingUrl = config.reportingUrl
        
        setupEvents(with: config)
        setupRemoteCallInstrumentation(with: config)
        setupCrashReporting(with: config)
        setupAlerts(with: config)
    }
    
    static func setupEvents(with config: InstanaConfiguration) {
        events.suspendReporting = config.suspendReporting
        events.bufferSize = config.eventsBufferSize
        events.submit(event: InstanaSessionProfileEvent())
    }
    
    static func setupRemoteCallInstrumentation(with config: InstanaConfiguration) {
        remoteCallInstrumentation.type = config.remoteCallInstrumentationType
    }
    
    static func setupCrashReporting(with config: InstanaConfiguration) {
        if config.enableCrashReporting == true {
            crashReporting.setup()
        }
    }
    
    static func setupAlerts(with config: InstanaConfiguration) {
        alerts.applicationNotRespondingTreshold = config.alertApplicationNotRespondingTreshold
        alerts.framerateDipTreshold = config.alertFramerateDipTreshold
        alerts.lowMemory = config.alertLowMemory
    }
}
