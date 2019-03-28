//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Root object of the Instana SDK.
///
/// Besides setup, this class is used as a namespace for all of Instanas features. For example:
///
///     Instana.events.submit(event: myEvent)
///
/// - Important: Before using any of Instana's features, it is necessary to invoke one of its setup methods.
@objc public class Instana: NSObject {
    
    /// Object acting as a namespace for configuring alerts.
    @objc public static let alerts = InstanaAlerts()
    
    /// Object acting as a namespace for configuring and using events.
    @objc public static let events = InstanaEvents()
    
    /// Object acting as a namespace for configuring crash reporting.
    @objc public static let crashReporting = InstanaCrashReporting()
    
    /// Object acting as a namespace for configuring and using remote call instrumentation.
    @objc public static let remoteCallInstrumentation = InstanaRemoteCallInstrumentation()
    
    static let log = InstanaLogger()
    static let battery = InstanaBatteryUtils()

    @objc public static let sessionId = UUID().uuidString
    private(set) static var reportingUrl = InstanaConfiguration.Defaults.reportingUrl
    private(set) static var key: String?
    
    private override init() {}
    
    /// Configures and sets up the Instana SDK.
    ///
    /// Looks for `InstanaConfiguration.plist` in the main bundle.
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    @objc public static func setup() {
        let defaultPath = Bundle.main.path(forResource: "InstanaConfiguration", ofType: ".plist")
        guard let config = InstanaConfiguration.read(from: defaultPath) else { return }
        setup(with: config)
    }
    
    
    /// Configures and sets up the Instana SDK with a configuration file at a custom path.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameter configPath: absolute path to the configuration file.
    @objc public static func setup(with configPath: String) {
        guard let config = InstanaConfiguration.read(from: configPath) else { return }
        setup(with: config)
    }
    
    /// Configures and sets up the Instana SDK with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key identifying your application.
    ///   - reportingUrl: Optional reporting url used for on-premises Instana backend installations.
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
        public typealias Bytes = Int64
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
        remoteCallInstrumentation.reporting = config.remoteCallInstrumentationType
    }
    
    static func setupCrashReporting(with config: InstanaConfiguration) {
        if config.enableCrashReporting == true {
            crashReporting.setup()
        }
    }
    
    static func setupAlerts(with config: InstanaConfiguration) {
        alerts.applicationNotRespondinThreshold = config.alertApplicationNotRespondingThreshold
        alerts.framerateDipThreshold = config.alertFramerateDipThreshold
        alerts.lowMemory = config.alertLowMemory
    }
}
