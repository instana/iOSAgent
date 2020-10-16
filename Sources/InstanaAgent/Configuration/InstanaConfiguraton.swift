import Foundation

@objc public enum HTTPCaptureConfig: Int {
    /// HTTP requestes & responses will be captured automatically (Default configuration)
    case automatic
    /// HTTP requestes & responses must be captured manually via ```Instana.startCapture(request)```
    case manual
    /// Don't capture any http requests or responses
    case none
}

struct InstanaConfiguration: Equatable {
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

        static let defaults: Set<MonitorTypes> = [.http,
                                                  .memoryWarning,
                                                  .framerateDrop(frameThreshold: 20),
                                                  .alertApplicationNotResponding(threshold: 2.0)]
    }

    struct Defaults {
        static let transmissionDelay: Instana.Types.Seconds = 1.0
        static let transmissionLowBatteryDelay: Instana.Types.Seconds = 10.0
        static let gzipReport = ProcessInfo.ignoreZIPReporting ? false : true
        static let maxBeaconsPerRequest = 100
        static let preQueueUsageTime: TimeInterval = 2.0
        static let reporterRateLimits = [ReporterRateLimitConfig(timeout: 10, maxItems: 20),
                                         ReporterRateLimitConfig(timeout: 60 * 5, maxItems: 200)]
    }

    var reportingURL: URL
    var key: String
    var httpCaptureConfig: HTTPCaptureConfig
    var suspendReporting: Set<SuspendReporting>
    var monitorTypes: Set<MonitorTypes>
    var transmissionDelay: Instana.Types.Seconds
    var transmissionLowBatteryDelay: Instana.Types.Seconds
    var gzipReport: Bool
    var maxBeaconsPerRequest: Int
    var preQueueUsageTime: TimeInterval
    var reporterRateLimits: [ReporterRateLimitConfig]
    var isValid: Bool { !key.isEmpty && !reportingURL.absoluteString.isEmpty }

    static var empty: InstanaConfiguration {
        .default(key: "", reportingURL: URL(string: "https://www.instana.com")!, httpCaptureConfig: .none)
    }

    static func `default`(key: String, reportingURL: URL, httpCaptureConfig: HTTPCaptureConfig = .automatic) -> InstanaConfiguration {
        self.init(reportingURL: reportingURL,
                  key: key,
                  httpCaptureConfig: httpCaptureConfig,
                  suspendReporting: SuspendReporting.defaults,
                  monitorTypes: MonitorTypes.defaults,
                  transmissionDelay: Defaults.transmissionDelay,
                  transmissionLowBatteryDelay: Defaults.transmissionLowBatteryDelay,
                  gzipReport: Defaults.gzipReport,
                  maxBeaconsPerRequest: Defaults.maxBeaconsPerRequest,
                  preQueueUsageTime: Defaults.preQueueUsageTime,
                  reporterRateLimits: Defaults.reporterRateLimits)
    }
}
