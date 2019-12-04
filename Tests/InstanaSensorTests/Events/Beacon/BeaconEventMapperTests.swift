//
//  BeaconEventMapperTests.swift
//  
//
//  Created by Christian Menschel on 29.11.19.
//

import Foundation
import XCTest
@testable import InstanaSensor

class BeaconEventMapperTests: XCTestCase {

    var config: InstanaConfiguration!

    override func setUp() {
        super.setUp()
        config = InstanaConfiguration.default(key: "KEY")
    }

    func test_undefined_beacon_type() {
        // Given
        let event = Event()
        let mapper = BeaconEventMapper(config)

        // When
        XCTAssertThrowsError(try mapper.map(event)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
    }

    func test_map_session() {
        let sessionID = "ID-\((0...100).randomElement() ?? 0)"
        let timestamp = Date().millisecondsSince1970
        let event = SessionProfileEvent(state: .start, timestamp: timestamp, sessionId: sessionID)
        let mapper = BeaconEventMapper(config)

        // When
        guard let sut = try? mapper.map(event) else {
            XCTFail("Could not map event to beacon")
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
        let event = HTTPEvent(timestamp: timestamp,
                              method: method,
                              url: url,
                              connectionType: .wifi,
                              result: "RESULT")
        let mapper = BeaconEventMapper(config)

        // When
        guard let sut = try? mapper.map(event) else {
            XCTFail("Could not map event to beacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.hu, url.absoluteString)
        AssertEqualAndNotNil(sut.hp, url.path)
        AssertEqualAndNotNil(sut.hs, String(event.responseCode))
        AssertEqualAndNotNil(sut.hm, method)
        AssertEqualAndNotNil(sut.trs, String(event.responseSize))
        AssertEqualAndNotNil(sut.d, String(event.duration))

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 24)
    }
}
