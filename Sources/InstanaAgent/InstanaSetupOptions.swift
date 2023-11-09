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
         usiRefreshTimeIntervalInHrs: Double = defaultUsiRefreshTimeIntervalInHrs) {
        self.httpCaptureConfig = httpCaptureConfig
        self.collectionEnabled = collectionEnabled
        self.enableCrashReporting = enableCrashReporting
        self.suspendReportingOnLowBattery = suspendReportingOnLowBattery
        self.suspendReportingOnCellular = suspendReportingOnCellular
        self.slowSendInterval = slowSendInterval
        self.usiRefreshTimeIntervalInHrs = usiRefreshTimeIntervalInHrs
    }
}
