//
//  CoreBeaconFactoryTests.swift
//  
//
//  Created by Christian Menschel on 29.11.19.
//

import Foundation
import XCTest
@testable import InstanaSensor

class CoreBeaconFactoryTests: XCTestCase {

    var config: InstanaConfiguration!

    override func setUp() {
        super.setUp()
        config = InstanaConfiguration.default(key: "KEY")
    }

    func test_undefined_beacon_type() {
        // Given
        let beacon = Beacon()
        let mapper = CoreBeaconFactory(config)

        // When
        XCTAssertThrowsError(try mapper.map(beacon)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
    }

    func test_map_session() {
        let sessionID = "ID-\((0...100).randomElement() ?? 0)"
        let timestamp = Date().millisecondsSince1970
        let beacon = SessionProfileBeacon(state: .start, timestamp: timestamp, sessionId: sessionID)
        let mapper = CoreBeaconFactory(config)

        // When
        guard let sut = try? mapper.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .sessionStart)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 18)
    }

    func test_map_http() {
        // Given
        let url = URL.random
        let method = "POST"
        let timestamp = Date().millisecondsSince1970
        let beacon = HTTPBeacon(timestamp: timestamp,
                              method: method,
                              url: url,
                              connectionType: .wifi,
                              result: "RESULT")
        let mapper = CoreBeaconFactory(config)

        // When
        guard let sut = try? mapper.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.hu, url.absoluteString)
        AssertEqualAndNotNil(sut.hp, url.path)
        AssertEqualAndNotNil(sut.hs, String(beacon.responseCode))
        AssertEqualAndNotNil(sut.hm, method)
        AssertEqualAndNotNil(sut.trs, String(beacon.responseSize))
        AssertEqualAndNotNil(sut.d, String(beacon.duration))

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 24)
    }
}
