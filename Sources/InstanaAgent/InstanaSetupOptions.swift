//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

@objc public class InstanaSetupOptions: NSObject {
    public var httpCaptureConfig: HTTPCaptureConfig
    public var collectionEnabled: Bool
    public var enableCrashReporting: Bool
    public var suspendReportingOnLowBattery: Bool
    public var suspendReportingOnCellular: Bool
    public var slowSendInterval: Instana.Types.Seconds
    public var usiRefreshTimeIntervalInHrs: Double

    // If autoCaptureScreenNames is set to true, we could leverage
    // certain classes' properties and set active view name automatically.
    // The class needs to derive from UIViewController directly or indirectly.
    // Instana.setView is triggered on the instance's viewDidAppear call.
    public var autoCaptureScreenNames: Bool
    public var debugAllScreenNames: Bool

    public var queryTrackedDomainList: [NSRegularExpression]?

    // Toggle the reporting of dropped beacon samples.
    // Note: Disabling this will prevent the CUSTOM EVENT named
    // "INSTANA_DROPPED_BEACON_SAMPLE" from being sent, which includes metadata
    // about the sampled dropped beacons.
    public var dropBeaconReporting: Bool

    @objc public var perfConfig: InstanaPerformanceConfig?

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
         perfConfig: InstanaPerformanceConfig? = nil) {
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
        self.perfConfig = perfConfig
        super.init()
    }
}

@objc public class InstanaPerformanceConfig: NSObject {
    var enableAppStartTimeReport: Bool = false
    var enableAnrReport: Bool = false
    var anrThreshold: Double = 3.0 // in seconds
    var enableOOMReport: Bool = false

    @objc public
    init(enableAppStartTimeReport: Bool = false, enableAnrReport: Bool = false, anrThreshold: Double = 3.0,
         enableOOMReport: Bool = false) {
        self.enableAppStartTimeReport = enableAppStartTimeReport
        self.enableAnrReport = enableAnrReport
        self.anrThreshold = anrThreshold
        self.enableOOMReport = enableOOMReport
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
    func setEnableOOMReport(_ enableOOMReport: Bool) {
        self.enableOOMReport = enableOOMReport
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
