//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaConfigurationTests: XCTestCase {
    
    func test_defaultValues() {
        let config = InstanaConfiguration.default(key: "a", reportingUrl: nil)
        XCTAssertEqual(config.key, "a")
        assertDefaultValues(in: config)
    }
    
    func test_passedReportingUrl_overridesDefault() {
        XCTAssertEqual(InstanaConfiguration.default(key: "a", reportingUrl: "b").reportingUrl, "b")
    }
    
    func test_randomPath_shouldNotReturnConfig() {
        XCTAssertNil(InstanaConfiguration.read(from: "aaa"))
    }
    
    func test_plistWithoutKey_shouldNotReturnConfig() {
        let url = selfCleaningTempFileURL(name: "TestConfig.plist")
        let configDict: NSDictionary = [:]
        configDict.write(to: url, atomically: true)

        XCTAssertNil(InstanaConfiguration.read(from: url.path))
    }
    
    func test_plistWithKey_shouldReturnConfigWithKeyAndDefaultValues() {
        let url = selfCleaningTempFileURL(name: "TestConfig.plist")
        let configDict: NSDictionary = ["key": "a"]
        configDict.write(to: url, atomically: true)
        
        let config = InstanaConfiguration.read(from: url.path)
        
        typealias d = InstanaConfiguration.Defaults
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.key, "a")
        assertDefaultValues(in: config)
    }
    
    func xtest_plistValues_shouldBeParsedToConfig() {
        let url = selfCleaningTempFileURL(name: "TestConfig.plist")
        let configDict: NSDictionary = [
            "key": "a",
            "reportingUrl": "b",
            "remoteCallInstrumentationType": 1,
            "suspendReporting": 1,
            "eventsBufferSize": 1000,
            "sendDeviceLocationIfAvailable": true,
            "alertApplicationNotRespondingThreshold": 2,
            "alertLowMemory": true,
            "alertFramerateDropThreshold": 1
        ]
        configDict.write(to: url, atomically: true)
        
        let config = InstanaConfiguration.read(from: url.path)
        
        XCTAssertEqual(config?.key, "a")
        XCTAssertEqual(config?.reportingUrl, "b")
        XCTAssertEqual(config?.remoteCallInstrumentationType, HTTPMonitor.ReportingType(rawValue: 1))
        XCTAssertEqual(config?.suspendReporting, BeaconReporter.SuspendReporting(rawValue: 1))
        XCTAssertEqual(config?.eventsBufferSize, 1000)
        XCTAssertEqual(config?.sendDeviceLocationIfAvailable, true)
        XCTAssertEqual(config?.alertApplicationNotRespondingThreshold, 2)
        XCTAssertEqual(config?.alertLowMemory, true)
        XCTAssertEqual(config?.alertFramerateDropThreshold, 1)
    }
    
    func test_invalidlyTypedPlistValues_shouldFallbackToDefaults() {
        let url = selfCleaningTempFileURL(name: "TestConfig.plist")
        let configDict: NSDictionary = [
            "key": "a",
            "reportingUrl": 1,
            "remoteCallInstrumentationType": "a",
            "suspendReporting": "a",
            "eventsBufferSize": "a",
            "sendDeviceLocationIfAvailable": "a",
            "alertApplicationNotRespondingThreshold": "a",
            "alertLowMemory": "a",
            "alertFramerateDropThreshold": "a"
        ]
        configDict.write(to: url, atomically: true)
        
        let config = InstanaConfiguration.read(from: url.path)
        assertDefaultValues(in: config)
    }
}

extension InstanaConfigurationTests {
    func assertDefaultValues(in config: InstanaConfiguration?, file: StaticString = #file, line: UInt = #line) {
        typealias d = InstanaConfiguration.Defaults
        XCTAssertNotNil(config, file: file, line: line)
        XCTAssertEqual(config?.reportingUrl, d.reportingUrl, file: file, line: line)
        XCTAssertEqual(config?.remoteCallInstrumentationType, d.remoteCallInstrumentationType, file: file, line: line)
        XCTAssertEqual(config?.suspendReporting, d.suspendReporting, file: file, line: line)
        XCTAssertEqual(config?.eventsBufferSize, d.eventsBufferSize, file: file, line: line)
        XCTAssertEqual(config?.sendDeviceLocationIfAvailable, d.sendDeviceLocationIfAvailable, file: file, line: line)
        XCTAssertEqual(config?.alertApplicationNotRespondingThreshold, d.alertApplicationNotRespondingThreshold, file: file, line: line)
        XCTAssertEqual(config?.alertLowMemory, d.alertLowMemory, file: file, line: line)
        XCTAssertEqual(config?.alertFramerateDropThreshold, d.alertFramerateDropThreshold, file: file, line: line)
    }
}
