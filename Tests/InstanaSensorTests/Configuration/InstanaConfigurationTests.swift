//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaConfigurationTests: XCTestCase {
    
    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a", reportingURL: nil)
        XCTAssertEqual(config.key, "a")
        assertDefaultValues(in: config)
    }
}

extension InstanaConfigurationTests {
    func assertDefaultValues(in config: InstanaConfiguration?, file: StaticString = #file, line: UInt = #line) {
        typealias d = InstanaConfiguration.Defaults
        XCTAssertNotNil(config, file: file, line: line)
        XCTAssertEqual(config?.reportingURL, d.reportingURL, file: file, line: line)
        XCTAssertEqual(config?.remoteCallInstrumentationType, d.remoteCallInstrumentationType, file: file, line: line)
        XCTAssertEqual(config?.suspendReporting, d.suspendReporting, file: file, line: line)
        XCTAssertEqual(config?.eventsBufferSize, d.eventsBufferSize, file: file, line: line)
        XCTAssertEqual(config?.sendDeviceLocationIfAvailable, d.sendDeviceLocationIfAvailable, file: file, line: line)
        XCTAssertEqual(config?.alertApplicationNotRespondingThreshold, d.alertApplicationNotRespondingThreshold, file: file, line: line)
        XCTAssertEqual(config?.alertLowMemory, d.alertLowMemory, file: file, line: line)
        XCTAssertEqual(config?.alertFramerateDropThreshold, d.alertFramerateDropThreshold, file: file, line: line)
    }
}
