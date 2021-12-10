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
        InstanaConfiguration(reportingURL: reportingURL,
                             key: key,
                             httpCaptureConfig: httpCaptureConfig,
                             suspendReporting: [],
                             monitorTypes: [.http,
                                            .memoryWarning,
                                            .framerateDrop(frameThreshold: 20),
                                            .alertApplicationNotResponding(threshold: 2.0)],
                             reporterSendDebounce: debounce,
                             reporterSendLowBatteryDebounce: debounce,
                             maxRetries: maxRetries,
                             gzipReport: gzipReport,
                             maxBeaconsPerRequest: maxBeaconsPerRequest,
                             maxQueueSize: maxQueueSize,
                             preQueueUsageTime: 0.0,
                             reporterRateLimits: [.init(timeout: 10.0, maxItems: 10), .init(timeout: 60.0, maxItems: 20)])
    }
}
