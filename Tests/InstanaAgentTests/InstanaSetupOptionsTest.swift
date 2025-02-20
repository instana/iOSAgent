//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaPerformanceConfigTests: XCTestCase {
    func test_enableAppStartTimeReport() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertFalse(pfConfig.enableAppStartTimeReport)

        // When
        pfConfig.setEnableAppStartTimeReport(true)

        // Then
        AssertTrue(pfConfig.enableAppStartTimeReport)
    }

    func test_setEnableAnrReport() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertFalse(pfConfig.enableAnrReport)

        // When
        pfConfig.setEnableAnrReport(true)

        // Then
        AssertTrue(pfConfig.enableAnrReport)
    }

    func test_setAnrThreshold() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertEqualAndNotNil(pfConfig.anrThreshold, 3.0)

        // When
        pfConfig.anrThreshold = 6.0

        // Then
        AssertEqualAndNotNil(pfConfig.anrThreshold, 6.0)
    }

    func test_setEnableOOMReport() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertFalse(pfConfig.enableOOMReport)

        // When
        pfConfig.setEnableOOMReport(true)

        // Then
        AssertTrue(pfConfig.enableOOMReport)
    }

    func testInit_full() {
        let pfConfig = InstanaPerformanceConfig(enableAppStartTimeReport: true,
                                                enableAnrReport: true, anrThreshold: 2.0,
                                                enableOOMReport: true)
        AssertEqualAndNotNil(pfConfig.enableAppStartTimeReport, true)
        AssertEqualAndNotNil(pfConfig.anrThreshold, 2.0)
        AssertEqualAndNotNil(pfConfig.enableOOMReport, true)
        AssertEqualAndNotNil(pfConfig.enableAnrReport, true)
    }

    func testInit_override() {
        let pfConfig = InstanaPerformanceConfig()
        AssertEqualAndNotNil(pfConfig.enableAppStartTimeReport, false)
        AssertEqualAndNotNil(pfConfig.enableAnrReport, false)
        AssertEqualAndNotNil(pfConfig.anrThreshold, 3.0)
        AssertEqualAndNotNil(pfConfig.enableOOMReport, false)
    }
}

class HybridAgentOptionsTests: XCTestCase {
    func test_init() {
        let mco = HybridAgentOptions(id:"f", version:"3.0.6")
        AssertEqualAndNotNil(mco.id, "f")
        AssertEqualAndNotNil(mco.version, "3.0.6")

        let mcoTooLong = HybridAgentOptions(id:"react-native-agent", version:"2.0.3")
        AssertEqualAndNotNil(mcoTooLong.id, "react-native-age")
        AssertEqualAndNotNil(mcoTooLong.version, "2.0.3")

        let mcoMisConfiged = HybridAgentOptions(id:"", version:"")
        AssertEqualAndNotNil(mcoMisConfiged.id, "")
        AssertEqualAndNotNil(mcoMisConfiged.version, "")
    }
}
