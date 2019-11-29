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

    func test_undefined_beacon_type() {
        // Given
        let event = Event()
        let mapper = BeaconEventMapper(key: "")

        // When
        XCTAssertThrowsError(try mapper.map(event)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
    }

    func test_map_to_http_beacon() {
        // Given
        let key = "KEY123"
        let url = "http://www.example.com/some/path"
        let method = "POST"
        let timestamp = Date().millisecondsSince1970
        let event = HTTPEvent(timestamp: timestamp,
                              method: method,
                              url: url,
                              connectionType: .wifi,
                              result: "RESULT")
        let mapper = BeaconEventMapper(key: key)

        // When
        guard let sut = try? mapper.map(event) else {
            XCTFail("Could not map event to beacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.hu, url)
        AssertEqualAndNotNil(sut.hp, "/some/path")
        AssertEqualAndNotNil(sut.hs, event.responseCode)
        AssertEqualAndNotNil(sut.hm, method)
        AssertEqualAndNotNil(sut.trs, event.responseSize)
        AssertEqualAndNotNil(sut.d, event.duration)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 23)
    }
}
