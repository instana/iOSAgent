import XCTest
@testable import InstanaAgent

class InstanaConfigurationTests: InstanaTestCase {
    let url = URL(string: "http://localhost:3000")!

    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: true,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)
        AssertTrue(config.key == "a")
        AssertEqualAndNotNil(config.reportingURL, url)
        AssertEqualAndNotNil(config.httpCaptureConfig, .automatic)
        AssertEqualAndNotNil(config.slowSendInterval, 0.0)
        AssertTrue(config.usiRefreshTimeIntervalInHrs == defaultUsiRefreshTimeIntervalInHrs)
        AssertTrue(config.suspendReporting.isEmpty)
        AssertTrue(config.maxRetries == 3)
        AssertTrue(config.maxBeaconsPerRequest == 100)
        AssertTrue(config.maxQueueSize == 1000)
        AssertTrue(config.reporterSendDebounce == 2)
        AssertTrue(config.maxRetries == 3)
        AssertTrue(config.preQueueUsageTime == 2)
        AssertTrue(config.reporterSendLowBatteryDebounce == 10)
        AssertTrue(config.monitorTypes.count == 3)
        AssertTrue(config.monitorTypes.contains(.http))
        AssertTrue(config.reporterRateLimits.count == 2)
        AssertTrue(config.reporterRateLimits.first?.maxItems == 20)
        AssertTrue(config.reporterRateLimits.last?.maxItems == 500)
        AssertTrue(config.reporterRateLimits.first?.timeout == 10)
        AssertTrue(config.reporterRateLimits.last?.timeout == 300)
        //        AssertTrue(config.monitorTypes.contains(.framerateDrop(frameThreshold: 20)))
    }

    func test_monitors() {
        let perfConfig = InstanaPerformanceConfig(enableAppStartTimeReport: true,
                                                  enableAnrReport: true,
                                                  anrThreshold: 5.0,
                                                  enableLowMemoryReport: true)
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: true,
                                                  perfConfig: perfConfig,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)

        AssertTrue(config.monitorTypes.contains(.appLaunchTime))
        AssertTrue(config.monitorTypes.contains(.memoryWarning))
        AssertTrue(config.monitorTypes.contains(.alertApplicationNotResponding(threshold: 5.0)))
    }

    func test_rateLimits_default() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: true,
                                                  rateLimits: RateLimits.DEFAULT_LIMITS,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)

        AssertTrue(config.reporterRateLimits == InstanaConfiguration.Defaults.reporterRateLimits)
    }

    func test_rateLimits_mid() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: true,
                                                  rateLimits: RateLimits.MID_LIMITS,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)

        AssertTrue(config.reporterRateLimits.count == 2)

        var limiter = config.reporterRateLimits[0]
        AssertEqualAndNotNil(limiter.timeout, 10)
        AssertEqualAndNotNil(limiter.maxItems, 40)

        limiter = config.reporterRateLimits[1]
        AssertEqualAndNotNil(limiter.timeout, 60 * 5)
        AssertEqualAndNotNil(limiter.maxItems, 1000)
    }

    func test_rateLimits_max() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: true,
                                                  rateLimits: RateLimits.MAX_LIMITS,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)

        AssertTrue(config.reporterRateLimits.count == 2)

        var limiter = config.reporterRateLimits[0]
        AssertEqualAndNotNil(limiter.timeout, 10)
        AssertEqualAndNotNil(limiter.maxItems, 100)

        limiter = config.reporterRateLimits[1]
        AssertEqualAndNotNil(limiter.timeout, 60 * 5)
        AssertEqualAndNotNil(limiter.maxItems, 2500)
    }

    func test_performance_default() {
        let config = InstanaConfiguration.default(key: "a",
                                                  reportingURL: url,
                                                  enableCrashReporting: false,
                                                  deleteOldBeacons: false,
                                                  maxBeaconResendTries: testMaxBeaconResendTries,
                                                  timeoutInterval: defaultTimeoutInterval)
        AssertTrue(config.monitorTypes.contains(.appLaunchTime))
        AssertFalse(config.monitorTypes.contains(.memoryWarning))
        AssertFalse(config.monitorTypes.contains(.alertApplicationNotResponding(threshold: 3.0)))
    }
}
