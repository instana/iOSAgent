//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

@objc public enum HTTPCaptureConfig: Int {
    /// HTTP requestes & responses will be captured automatically (Default configuration)
    case automatic
    /// HTTP requestes & responses must be captured manually via ```Instana.startCapture(request)```
    case manual
    /// HTTP requestes & responses can be captured automatically and manually
    case automaticAndManual
    /// Don't capture any http requests or responses
    case none
}

// Use a reference type to avoid a copy when having concurrency
class InstanaConfiguration {
    enum SuspendReporting {
        /// Reporting is suspended while the device battery is low.
        case lowBattery
        /// Reporting is suspended while the device is using a cellular connection.
        case cellularConnection

        static let defaults: Set<SuspendReporting> = []
    }

    struct ReporterRateLimitConfig: Equatable {
        let timeout: TimeInterval
        let maxItems: Int
    }

    enum MonitorTypes: Hashable {
        case http
        case memoryWarning
        case framerateDrop(frameThreshold: UInt)
        case alertApplicationNotResponding(threshold: Instana.Types.Seconds)
        case crash

        static let current: Set<MonitorTypes> = [.http]
        static let all: Set<MonitorTypes> = [.http,
                                             .memoryWarning,
                                             .framerateDrop(frameThreshold: 20),
                                             .alertApplicationNotResponding(threshold: 3.0)]
    }

    struct Defaults {
        static let reporterSendDebounce: Instana.Types.Seconds = 2.0
        static let reporterSendLowBatteryDebounce: Instana.Types.Seconds = 10.0
        static let gzipReport = ProcessInfo.ignoreZIPReporting ? false : true
        static let maxRetries = 3
        static let maxBeaconsPerRequest = 100
        static let maxQueueSize = 1000
        static let preQueueUsageTime: TimeInterval = 2.0
        static let reporterRateLimits = [ReporterRateLimitConfig(timeout: 10, maxItems: 20),
                                         ReporterRateLimitConfig(timeout: 60 * 5, maxItems: 500)]
    }

    var reportingURL: URL
    var key: String
    var httpCaptureConfig: HTTPCaptureConfig
    var suspendReporting: Set<SuspendReporting>
    var monitorTypes: Set<MonitorTypes>
    var slowSendInterval: Instana.Types.Seconds
    var usiRefreshTimeIntervalInHrs: Double
    var reporterSendDebounce: Instana.Types.Seconds
    var reporterSendLowBatteryDebounce: Instana.Types.Seconds
    var maxRetries: Int
    var gzipReport: Bool
    var maxBeaconsPerRequest: Int = 0
    var maxQueueSize: Int
    var preQueueUsageTime: TimeInterval
    var reporterRateLimits: [ReporterRateLimitConfig]
    var isValid: Bool { !key.isEmpty && !reportingURL.absoluteString.isEmpty }
    // set if iOSAgent is invoked by flutter-agent or react-native-agent
    var hybridAgentId: String?
    var hybridAgentVersion: String?

    required init(reportingURL: URL, key: String, httpCaptureConfig: HTTPCaptureConfig,
                  enableCrashReporting: Bool, suspendReporting: Set<SuspendReporting>? = nil,
                  slowSendInterval: Instana.Types.Seconds,
                  usiRefreshTimeIntervalInHrs: Double,
                  hybridAgentId: String?,
                  hybridAgentVersion: String?,
                  anrThreshold: Instana.Types.Milliseconds = -1) {
        self.reportingURL = reportingURL
        self.key = key
        self.httpCaptureConfig = httpCaptureConfig
        monitorTypes = MonitorTypes.current
        if anrThreshold > 0 {
            let anrInSeconds = Double(anrThreshold) / 1000.0
            monitorTypes.insert(.alertApplicationNotResponding(threshold: anrInSeconds))
        }
        if enableCrashReporting {
            monitorTypes.insert(.crash)
        }
        self.suspendReporting = suspendReporting ?? SuspendReporting.defaults
        self.slowSendInterval = slowSendInterval
        self.usiRefreshTimeIntervalInHrs = usiRefreshTimeIntervalInHrs
        self.hybridAgentId = hybridAgentId
        self.hybridAgentVersion = hybridAgentVersion
        reporterSendDebounce = Defaults.reporterSendDebounce
        reporterSendLowBatteryDebounce = Defaults.reporterSendLowBatteryDebounce
        maxRetries = Defaults.maxRetries
        gzipReport = Defaults.gzipReport
        maxBeaconsPerRequest = Defaults.maxBeaconsPerRequest
        maxQueueSize = Defaults.maxQueueSize
        preQueueUsageTime = Defaults.preQueueUsageTime
        reporterRateLimits = Defaults.reporterRateLimits
    }

    static func `default`(key: String, reportingURL: URL, httpCaptureConfig: HTTPCaptureConfig = .automatic,
                          enableCrashReporting: Bool,
                          suspendReporting: Set<SuspendReporting>? = nil,
                          slowSendInterval: Instana.Types.Seconds = 0.0,
                          usiRefreshTimeIntervalInHrs: Double = defaultUsiRefreshTimeIntervalInHrs,
                          hybridAgentId: String? = nil,
                          hybridAgentVersion: String? = nil,
                          anrThreshold: Instana.Types.Milliseconds = -1)
        -> InstanaConfiguration {
        self.init(reportingURL: reportingURL, key: key, httpCaptureConfig: httpCaptureConfig,
                  enableCrashReporting: enableCrashReporting,
                  suspendReporting: suspendReporting,
                  slowSendInterval: slowSendInterval,
                  usiRefreshTimeIntervalInHrs: usiRefreshTimeIntervalInHrs,
                  hybridAgentId: hybridAgentId,
                  hybridAgentVersion: hybridAgentVersion,
                  anrThreshold: anrThreshold)
    }
}
