//
//  File.swift
//  
//
//  Created by Christian Menschel on 29.11.19.
//

import XCTest
@testable import InstanaSensor

class BeaconTests: XCTestCase {

    func test_create_default() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let sut = Beacon.createDefault(key: "KEY123", timestamp: timestamp, sessionId: "SID", eventId: "EID")

        // Then
        AssertEqualAndNotNil(sut.k, "KEY123")
        AssertEqualAndNotZero(sut.ti, timestamp)
        AssertEqualAndNotNil(sut.sid, "SID")
        AssertEqualAndNotNil(sut.bid, "EID")
        AssertEqualAndNotNil(sut.buid, InstanaSystemUtils.applicationBundleIdentifier)
        AssertEqualAndNotNil(sut.lg, Locale.current.languageCode)
        AssertEqualAndNotNil(sut.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(sut.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(sut.osn, InstanaSystemUtils.systemName)
        AssertEqualAndNotNil(sut.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(sut.dmo, InstanaSystemUtils.deviceModel)
        AssertEqualAndNotNil(sut.ro, InstanaSystemUtils.isDeviceJailbroken)
        AssertEqualAndNotNil(sut.vw, Int(InstanaSystemUtils.screenSize.width))
        AssertEqualAndNotNil(sut.vh, Int(InstanaSystemUtils.screenSize.height))
        AssertEqualAndNotNil(sut.cn, InstanaSystemUtils.carrierName)
        AssertEqualAndNotNil(sut.ct, InstanaSystemUtils.connectionTypeDescription)
    }

    func testNumberOfFields_all() {
        // Given
        let sut = Beacon.createDefault(key: "KEY123")

        // When
        let values = Mirror(reflecting: sut).children

        // Then
        XCTAssertEqual(values.count, 33)
    }

    func testNumberOfFields_non_nil() {
        // Given
        let sut = Beacon.createDefault(key: "KEY123")

        // When
        let values = Mirror(reflecting: sut).nonNilChildren

        // Then
        XCTAssertEqual(values.count, 17)
    }


    func test_all_keys() {
        // Given
        let sut = Beacon.createDefault(key: "KEY123")
        // TODO: Add all keys of Beacon
        let expectedKeys = ["t", "bt", "k"]
    
        // When
        let keys = Mirror(reflecting: sut).children.compactMap {$0.label}

        // Then
        let matchingKeys = expectedKeys.filter {key in
            keys.contains(key)
        }

        XCTAssertEqual(expectedKeys.count, matchingKeys.count)
    }
}
