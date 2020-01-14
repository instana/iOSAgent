import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaConfiguration {
    static var mock: InstanaConfiguration {
        InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, httpCaptureConfig: .automatic)
    }

    static func mock(key: String = "KEY",
                     reportingURL: URL = .random,
                     httpCaptureConfig: HTTPCaptureConfig = .automatic) -> InstanaConfiguration {
        InstanaConfiguration(reportingURL: reportingURL,
                             key: key,
                             httpCaptureConfig: httpCaptureConfig,
                             suspendReporting: [],
                             monitorTypes: [.http,
                                            .memoryWarning,
                                            .framerateDrop(frameThreshold: 20),
                                            .alertApplicationNotResponding(threshold: 2.0)],
                             transmissionDelay: 0.0, transmissionLowBatteryDelay: 0.0,
                             gzipReport: true)
    }
}
