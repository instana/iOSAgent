import XCTest
@testable import InstanaAgent

class InstanaConfigurationTests: InstanaTestCase {
    
    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: URL(string: "http://localhost:3000")!,
                                                  enableCrashReporting: true)
        AssertEqualAndNotNil(config.key, "a")
        AssertEqualAndNotNil(config.reportingURL, URL(string: "http://localhost:3000")!)
        AssertEqualAndNotNil(config.httpCaptureConfig, .automatic)
        AssertEqualAndNotNil(config.slowSendInterval, 0.0)
        AssertEqualAndNotNil(config.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
        AssertTrue(config.suspendReporting.isEmpty)
        AssertEqualAndNotNil(config.maxRetries, 3)
        AssertTrue(config.maxBeaconsPerRequest == 100)
        AssertTrue(config.maxQueueSize == 1000)
        AssertTrue(config.reporterSendDebounce == 2)
        AssertTrue(config.maxRetries == 3)
        AssertTrue(config.preQueueUsageTime == 2)
        AssertTrue(config.reporterSendLowBatteryDebounce == 10)
        AssertTrue(config.monitorTypes.count == 2)
        AssertTrue(config.monitorTypes.contains(.http))
        AssertTrue(config.reporterRateLimits.count == 2)
        AssertTrue(config.reporterRateLimits.first?.maxItems == 20)
        AssertTrue(config.reporterRateLimits.last?.maxItems == 500)
        AssertTrue(config.reporterRateLimits.first?.timeout == 10)
        AssertTrue(config.reporterRateLimits.last?.timeout == 300)
//        AssertTrue(config.monitorTypes.contains(.memoryWarning))
//        AssertTrue(config.monitorTypes.contains(.alertApplicationNotResponding(threshold: 2.0)))
//        AssertTrue(config.monitorTypes.contains(.framerateDrop(frameThreshold: 20)))
    }
}
