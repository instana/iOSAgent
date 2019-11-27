//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Root object for the InstanaSensor.
///
///
/// - Important: Before using any of Instana's features, it is necessary to invoke one of its setup methods.
@objc public class Instana: NSObject {
    
    /// Object acting as a namespace for configuring alerts.
    @objc public static let alerts = InstanaAlerts()
    
    /// Object to manage and report events.
    @objc public static let eventReporter = EventReporter()

    /// Object acting as a namespace for configuring and using remote call instrumentation.
    @objc public static let remoteCallInstrumentation = HTTPMonitor()
    
    static let log = InstanaLogger()
    static let battery = InstanaBatteryUtils()

    @objc public static let sessionId = UUID().uuidString
    private(set) static var reportingUrl = InstanaConfiguration.Defaults.reportingUrl
    private(set) static var key: String?
    
    private override init() {}
    
//    /// Configures and sets up the Instana SDK.
//    ///
//    /// Looks for `InstanaConfiguration.plist` in the main bundle.
//    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
//    @objc public static func setup() {
//        let defaultPath = Bundle.main.path(forResource: "InstanaConfiguration", ofType: ".plist")
//        guard let config = InstanaConfiguration.read(from: defaultPath) else { return }
//        setup(config)
//    }
//    
//    
//    /// Configures and sets up the Instana SDK with a configuration file at a custom path.
//    ///
//    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
//    /// - Parameter configPath: absolute path to the configuration file.
//    @objc public static func setup(with configPath: String) {
//        guard let config = InstanaConfiguration.read(from: configPath) else { return }
//        setup(config)
//    }
    
    /// Configures and sets up the Instana SDK with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key identifying your application.
    ///   - reportingUrl: Optional reporting url used for on-premises Instana backend installations.
    @objc public static func setup(withKey key: String, reportingUrl: String? = nil) {
        let config = InstanaConfiguration.default(key: key, reportingUrl:  reportingUrl)
        setup(config)
    }
}

public extension Instana {
    @objc class Types: NSObject {
        private override init() {}
        public typealias Milliseconds = Int64
        public typealias Seconds = Double
        public typealias Bytes = Int64
    }
}

private extension Instana {    
    static func setup(_ config: InstanaConfiguration) {
        key = config.key
        reportingUrl = config.reportingUrl
        
        setupEventReporter(config)
        setupRemoteCallInstrumentation(config)
        setupAlerts(config)
    }
    
    static func setupEventReporter(_ config: InstanaConfiguration) {
        eventReporter.suspendReporting = config.suspendReporting
        eventReporter.bufferSize = config.eventsBufferSize
        eventReporter.submit(SessionProfileEvent())
    }
    
    static func setupRemoteCallInstrumentation(_ config: InstanaConfiguration) {
        remoteCallInstrumentation.reporting = config.remoteCallInstrumentationType
    }
    
    static func setupAlerts(_ config: InstanaConfiguration) {
        alerts.applicationNotRespondinThreshold = config.alertApplicationNotRespondingThreshold
        alerts.framerateDropThreshold = config.alertFramerateDropThreshold
        alerts.lowMemory = config.alertLowMemory
    }
}
