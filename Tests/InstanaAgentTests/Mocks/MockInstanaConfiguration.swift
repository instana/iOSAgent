//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaConfiguration {
    static var mock: InstanaConfiguration {
        .mock()
    }

    static func mock(key: String = "KEY",
                     reportingURL: URL = .random,
                     httpCaptureConfig: HTTPCaptureConfig = .automatic,
                     gzipReport: Bool = false,
                     maxBeaconsPerRequest: Int = 100,
                     maxQueueSize: Int = 80,
                     debounce: Instana.Types.Seconds = 0.0,
                     maxRetries: Int = 0) -> InstanaConfiguration {
        let config = InstanaConfiguration(reportingURL: reportingURL, key: key,
                                          httpCaptureConfig: httpCaptureConfig,
                                          enableCrashReporting: true)
        config.suspendReporting = []
        config.monitorTypes = [.http,
                               .memoryWarning,
                               .framerateDrop(frameThreshold: 20),
                               .alertApplicationNotResponding(threshold: 2.0),
                               MonitorTypes.crash]
        config.reporterSendDebounce = debounce
        config.reporterSendLowBatteryDebounce = debounce
        config.maxRetries = maxRetries
        config.gzipReport = gzipReport
        config.maxBeaconsPerRequest = maxBeaconsPerRequest
        config.maxQueueSize = maxQueueSize
        config.preQueueUsageTime = 0.0
        config.reporterRateLimits = [.init(timeout: 10.0, maxItems: 10), .init(timeout: 60.0, maxItems: 20)]
        return config
    }
}
