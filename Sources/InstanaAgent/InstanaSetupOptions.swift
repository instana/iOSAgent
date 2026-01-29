//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

@objc public class InstanaSetupOptions: NSObject {
    @objc public var httpCaptureConfig: HTTPCaptureConfig = .automatic
    @objc public var collectionEnabled: Bool = true
    @objc public var enableCrashReporting: Bool = false
    @objc public var suspendReportingOnLowBattery: Bool = false
    @objc public var suspendReportingOnCellular: Bool = false
    @available(*, deprecated, message: "Do not configure.")
    @objc public var slowSendInterval: Instana.Types.Seconds = 0.0
    @objc public var usiRefreshTimeIntervalInHrs: Double = defaultUsiRefreshTimeIntervalInHrs

    // If autoCaptureScreenNames is set to true, we could leverage
    // certain classes' properties and set active view name automatically.
    // The class needs to derive from UIViewController directly or indirectly.
    // Instana.setView is triggered on the instance's viewDidAppear call.
    @objc public var autoCaptureScreenNames: Bool = false
    @objc public var debugAllScreenNames: Bool = false

    @objc public var queryTrackedDomainList: [NSRegularExpression]?

    @objc public var dropBeaconReporting: Bool = false
    @objc public var rateLimits: RateLimits = .DEFAULT_LIMITS

    @objc public var perfConfig: InstanaPerformanceConfig?

    /**
     * When enabled, the backend will consider the device's (beacon creation) time as the actual time, rather than updating it to the ingestion time
     * (the time the beacon arrived at the server). If the beacon is received after 30 minutes, the ingestion time will be used instead.
     */
    @objc public var trustDeviceTiming: Bool = false

    // When set to true, this option includes W3C-compliant headers in HTTP request headers,
    // ensuring compatibility with W3C standards for tracing.
    @objc public var enableW3CHeaders: Bool = false

    /**
     * When enabled, this prevents beacons older than 15 minutes (saved while the device was offline) from being sent to the backend.
     */

    @objc public var deleteOldBeacons: Bool = false
    /**
     * Maximum beacon resend tries on sending failure
     * (note: On low battery or offline, beacon is not sent.)
     */
    @objc public var maxBeaconResendTries: Int = defaultMaxBeaconResendTries

    /**
     * timeoutInterval for sending beacons to backend server (URLRequest timeoutInterval) in seconds
     */
    @objc public var timeoutInterval: TimeInterval = defaultTimeoutInterval

    /// Instana custom configuration for setup.
    ///
    /// - Parameters:
    ///   - httpCaptureConfig: HTTP monitoring configuration to set the capture behavior (automatic, manual, automaticAndManual or none) HTTP requests & responses
    ///   - collectionEnabled: Enable or disable collection (instrumentation) on setup. Can be changed later via the property `collectionEnabled` (Default: true)
    ///   - enableCrashReporting: Subscribe to metricKit events so as to enable crash reporting.
    ///                           App must have explicitly asked user permission to subscribe before this call.
    ///   - slowSendInterval: Enable slow send mode on beacon send failure when a positive number is passed
    @objc public
    init(httpCaptureConfig: HTTPCaptureConfig = .automatic,
         collectionEnabled: Bool = true, enableCrashReporting: Bool = false,
         suspendReportingOnLowBattery: Bool = false,
         suspendReportingOnCellular: Bool = false,
         slowSendInterval: Instana.Types.Seconds = 0.0,
         usiRefreshTimeIntervalInHrs: Double = defaultUsiRefreshTimeIntervalInHrs,
         autoCaptureScreenNames: Bool = false,
         debugAllScreenNames: Bool = false,
         queryTrackedDomainList: [NSRegularExpression]? = nil,
         dropBeaconReporting: Bool = false,
         rateLimits: RateLimits = .DEFAULT_LIMITS,
         perfConfig: InstanaPerformanceConfig? = nil,
         trustDeviceTiming: Bool = false,
         enableW3CHeaders: Bool = false,
         deleteOldBeacons: Bool = false,
         maxBeaconResendTries: Int = defaultMaxBeaconResendTries,
         timeoutInterval: TimeInterval = defaultTimeoutInterval) {
        self.httpCaptureConfig = httpCaptureConfig
        self.collectionEnabled = collectionEnabled
        self.enableCrashReporting = enableCrashReporting
        self.suspendReportingOnLowBattery = suspendReportingOnLowBattery
        self.suspendReportingOnCellular = suspendReportingOnCellular
        self.slowSendInterval = slowSendInterval
        self.usiRefreshTimeIntervalInHrs = usiRefreshTimeIntervalInHrs
        self.autoCaptureScreenNames = autoCaptureScreenNames
        self.debugAllScreenNames = debugAllScreenNames
        self.queryTrackedDomainList = queryTrackedDomainList
        self.dropBeaconReporting = dropBeaconReporting
        self.rateLimits = rateLimits
        self.perfConfig = perfConfig
        self.trustDeviceTiming = trustDeviceTiming
        self.enableW3CHeaders = enableW3CHeaders
        self.deleteOldBeacons = deleteOldBeacons
        self.maxBeaconResendTries = maxBeaconResendTries
        if timeoutInterval > 60.0 {
            self.timeoutInterval = timeoutInterval
        }
        super.init()
    }

    @objc public
    override init() { super.init() }
}

@objc public class InstanaPerformanceConfig: NSObject {
    var enableAppStartTimeReport: Bool = true
    var enableAnrReport: Bool = false
    var anrThreshold: Double = 3.0 // in seconds
    var enableLowMemoryReport: Bool = false
    var enableAppStateDetection: Bool = true

    @objc public
    init(enableAppStartTimeReport: Bool = true, enableAnrReport: Bool = true,
         anrThreshold: Double = 3.0, enableLowMemoryReport: Bool = false,
         enableAppStateDetection: Bool = true) {
        self.enableAppStartTimeReport = enableAppStartTimeReport
        self.enableAnrReport = enableAnrReport
        self.anrThreshold = anrThreshold
        self.enableLowMemoryReport = enableLowMemoryReport
        self.enableAppStateDetection = enableAppStateDetection
        super.init()
    }

    @objc public
    override init() { super.init() }

    @objc public
    func setEnableAppStartTimeReport(_ enableAppStartTimeReport: Bool) {
        self.enableAppStartTimeReport = enableAppStartTimeReport
    }

    @objc public
    func setEnableAnrReport(_ enableAnrReport: Bool) {
        self.enableAnrReport = enableAnrReport
    }

    @objc public
    func setAnrThreshold(_ anrThreshold: Double) {
        self.anrThreshold = anrThreshold
    }

    @objc public
    func setEnableLowMemoryReport(_ enableLowMemoryReport: Bool) {
        self.enableLowMemoryReport = enableLowMemoryReport
    }

    @objc public
    func setEnableAppStateDetection(_ enableAppStateDetection: Bool) {
        self.enableAppStateDetection = enableAppStateDetection
    }
}

// Hybrid Agent options for setup
@objc public class HybridAgentOptions: NSObject {
    public private(set) var id: String
    public private(set) var version: String

    /// - Parameters:
    ///   - id: flutter-agent or react-native-agent
    ///   - version: version of flutter-agent or react-native-agent
    @objc public
    init(id: String, version: String) {
        // remove leading and trailing spaces
        // truncate if too long
        self.id = String(id.trimmingCharacters(in: .whitespaces).prefix(16))
        self.version = String(version.trimmingCharacters(in: .whitespaces).prefix(16))
    }
}
