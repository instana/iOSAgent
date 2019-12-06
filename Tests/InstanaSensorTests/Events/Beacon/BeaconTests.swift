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
        let sut = CoreBeacon.createDefault(key: "KEY123", timestamp: timestamp, sessionId: "SID", id: "EID")

        // Then
        AssertEqualAndNotNil(sut.k, "KEY123")
        AssertEqualAndNotNil(sut.ti, String(timestamp))
        AssertEqualAndNotNil(sut.sid, "SID")
        AssertEqualAndNotNil(sut.bid, "EID")
        AssertEqualAndNotNil(sut.buid, InstanaSystemUtils.applicationBundleIdentifier)
        AssertEqualAndNotNil(sut.ul, Locale.current.languageCode)
        AssertEqualAndNotNil(sut.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(sut.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(sut.osn, InstanaSystemUtils.systemName)
        AssertEqualAndNotNil(sut.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(sut.dmo, InstanaSystemUtils.deviceModel)
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.ro, String(InstanaSystemUtils.isDeviceJailbroken))
        AssertEqualAndNotNil(sut.vw, String(Int(InstanaSystemUtils.screenSize.width)))
        AssertEqualAndNotNil(sut.vh, String(Int(InstanaSystemUtils.screenSize.height)))
        AssertEqualAndNotNil(sut.cn, InstanaSystemUtils.carrierName)
        AssertEqualAndNotNil(sut.ct, InstanaSystemUtils.connectionTypeDescription)
    }

    func testNumberOfFields_all() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")

        // When
        let values = Mirror(reflecting: sut).children

        // Then
        XCTAssertEqual(values.count, 34)
    }

    func testNumberOfFields_non_nil() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")

        // When
        let values = Array(Mirror(reflecting: sut).nonNilChildren)

        // Then
        XCTAssertEqual(values.count, 18)
    }


    func test_all_keys() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")
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

    func test_formattedKVPair() {
        // Given
        let beacon = CoreBeacon.createDefault(key: "KEY123")
        let value = beacon.ab

        // When
        let sut = beacon.formattedKVPair(key: "ab", value: value)

        // When
        XCTAssertEqual(sut, "ab\t\(value)")
    }

    func test_formattedKVPair_nil_value() {
        // Given
        let beacon = CoreBeacon.createDefault(key: "KEY123")
        let value = Optional<Any>.none as Any

        // When
        let sut = beacon.formattedKVPair(key: "KEY", value: value)

        // When
        XCTAssertNil(sut)
    }

    func test_cleaning() {
        // Given
        var beacon = CoreBeacon.createDefault(key: "KEY123")
        beacon.bt = """

                        Trace ab

                    """

        // When
        let sut = beacon.cleaning(beacon.bt)

        // Then
        XCTAssertEqual(beacon.bt, "\n    Trace ab\n")
        XCTAssertEqual(sut, "Trace ab")
    }

    func test_truncate_at_max_length() {
        // Given
        let longString = (0...CoreBeacon.maxBytesPerField).map {"\($0)"}.joined()
        var beacon = CoreBeacon.createDefault(key: "KEY123")
        beacon.bt = longString

        // When
        let sut = beacon.cleaning(beacon.bt) ?? ""

        // Then
        XCTAssertTrue(sut.hasSuffix("…"))
    }
}
