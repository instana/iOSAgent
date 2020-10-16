import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaConfiguration {
    static var mock: InstanaConfiguration {
        InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, httpCaptureConfig: .automatic)
    }

    static func mock(key: String = "KEY",
                     reportingURL: URL = .random,
                     httpCaptureConfig: HTTPCaptureConfig = .automatic,
                     gzipReport: Bool = false) -> InstanaConfiguration {
        InstanaConfiguration(reportingURL: reportingURL,
                             key: key,
                             httpCaptureConfig: httpCaptureConfig,
                             suspendReporting: [],
                             monitorTypes: [.http,
                                            .memoryWarning,
                                            .framerateDrop(frameThreshold: 20),
                                            .alertApplicationNotResponding(threshold: 2.0)],
                             transmissionDelay: 0.0,
                             transmissionLowBatteryDelay: 0.0,
                             gzipReport: gzipReport,
                             maxBeaconsPerRequest: 100,
                             preQueueUsageTime: 0.0,
                             reporterRateLimits: [.init(timeout: 10.0, maxItems: 10), .init(timeout: 60.0, maxItems: 20)])
    }
}
