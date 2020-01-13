import XCTest
@testable import InstanaAgent

class InstanaConfigurationTests: InstanaTestCase {
    
    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a", reportingURL: nil)
        AssertEqualAndNotNil(config.key, "a")
        AssertEqualAndNotNil(config.reportingURL, URL(string: "http://localhost:3000")!)
        AssertEqualAndNotNil(config.httpCaptureConfig, .automatic)
        AssertTrue(config.suspendReporting.isEmpty)
        AssertTrue(config.monitorTypes.count == 4)
        AssertTrue(config.monitorTypes.contains(.http))
        AssertTrue(config.monitorTypes.contains(.memoryWarning))
        AssertTrue(config.monitorTypes.contains(.alertApplicationNotResponding(threshold: 2.0)))
        AssertTrue(config.monitorTypes.contains(.framerateDrop(frameThreshold: 20)))
    }
}
