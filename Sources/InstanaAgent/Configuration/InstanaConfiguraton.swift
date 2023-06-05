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
    static let maxSlowSendInterval = 3600.0

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
                                             .alertApplicationNotResponding(threshold: 2.0)]
    }

    struct Defaults {
        // 0 seconds means disable network probing
        static let slowSendInterval: Instana.Types.Seconds = 0.0
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
    var reporterSendDebounce: Instana.Types.Seconds
    var reporterSendLowBatteryDebounce: Instana.Types.Seconds
    var maxRetries: Int
    var gzipReport: Bool
    var maxBeaconsPerRequest: Int = 0
    var maxQueueSize: Int
    var preQueueUsageTime: TimeInterval
    var reporterRateLimits: [ReporterRateLimitConfig]
    var isValid: Bool { !key.isEmpty && !reportingURL.absoluteString.isEmpty }

    required init(reportingURL: URL, key: String, httpCaptureConfig: HTTPCaptureConfig,
                  enableCrashReporting: Bool, slowSendInterval: Double) {
        self.reportingURL = reportingURL
        self.key = key
        self.httpCaptureConfig = httpCaptureConfig
        suspendReporting = SuspendReporting.defaults
        monitorTypes = MonitorTypes.current
        if enableCrashReporting {
            monitorTypes.insert(.crash)
        }
        self.slowSendInterval = slowSendInterval
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
                          enableCrashReporting: Bool, slowSendInterval: Double = 0.0) -> InstanaConfiguration {
        self.init(reportingURL: reportingURL, key: key, httpCaptureConfig: httpCaptureConfig,
                  enableCrashReporting: enableCrashReporting, slowSendInterval: slowSendInterval)
    }
}
