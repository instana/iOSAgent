//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaSetupOptionsTests: XCTestCase {
    func test_init() {
        let options = InstanaSetupOptions()

        AssertTrue(options.httpCaptureConfig == .automatic)
        AssertTrue(options.collectionEnabled)
    }
}


class InstanaPerformanceConfigTests: XCTestCase {
    func test_enableAppStartTimeReport() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertTrue(pfConfig.enableAppStartTimeReport)

        // When
        pfConfig.setEnableAppStartTimeReport(false)

        // Then
        AssertFalse(pfConfig.enableAppStartTimeReport)
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
        pfConfig.setAnrThreshold(6.0)

        // Then
        AssertEqualAndNotNil(pfConfig.anrThreshold, 6.0)
    }

    func test_setEnableLowMemoryReport() {
        // Given
        let pfConfig = InstanaPerformanceConfig()
        AssertFalse(pfConfig.enableLowMemoryReport)

        // When
        pfConfig.setEnableLowMemoryReport(false)

        // Then
        AssertFalse(pfConfig.enableLowMemoryReport)
    }

    func testInit_full() {
        let pfConfig = InstanaPerformanceConfig(enableAppStartTimeReport: true,
                                                enableAnrReport: true, anrThreshold: 2.0,
                                                enableLowMemoryReport: true)
        AssertEqualAndNotNil(pfConfig.enableAppStartTimeReport, true)
        AssertEqualAndNotNil(pfConfig.anrThreshold, 2.0)
        AssertEqualAndNotNil(pfConfig.enableLowMemoryReport, true)
        AssertEqualAndNotNil(pfConfig.enableAnrReport, true)
    }

    func testInit_override() {
        let pfConfig = InstanaPerformanceConfig()
        AssertEqualAndNotNil(pfConfig.enableAppStartTimeReport, true)
        AssertEqualAndNotNil(pfConfig.enableAnrReport, false)
        AssertEqualAndNotNil(pfConfig.anrThreshold, 3.0)
        AssertEqualAndNotNil(pfConfig.enableLowMemoryReport, false)
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
