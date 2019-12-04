//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaConfigurationTests: XCTestCase {
    
    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a", reportingURL: nil)
        AssertEqualAndNotNil(config.key, "a")
        AssertEqualAndNotNil(config.reportingURL, URL(string: "http://localhost:3000")!)
        AssertEqualAndNotNil(config.reportingType, .automaticAndManual)
        AssertTrue(config.suspendReporting.isEmpty)
        AssertTrue(config.monitorTypes.count == 4)
        AssertTrue(config.monitorTypes.contains(.http))
        AssertTrue(config.monitorTypes.contains(.memoryWarning))
        AssertTrue(config.monitorTypes.contains(.alertApplicationNotResponding(threshold: 2.0)))
        AssertTrue(config.monitorTypes.contains(.framerateDrop(frameThreshold: 20)))
    }
}
