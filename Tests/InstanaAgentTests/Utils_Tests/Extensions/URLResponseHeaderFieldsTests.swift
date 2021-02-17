//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest

@testable import InstanaAgent

class URLResponseHeaderFieldsTests: InstanaTestCase {

    func test_backendTracingID_happy_path() {
        // Given
        let backendTracingID = "d2f7aebc1ee0813c"
        let headerFields = ["Server-Timing": "intid;desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        AssertEqualAndNotNil(sut, backendTracingID)
    }

    func test_backendTracingID_happy_path_lowercase() {
        // Given
        let backendTracingID = "d2f7aebc1ee0813c"
        let headerFields = ["server-timing": "intid;desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        AssertEqualAndNotNil(sut, backendTracingID)
    }

    func test_backendTracingID_multiple_values() {
        // Given
        let backendTracingID = "d2f7aebc1ee0813c"
        let headerFields = ["server-timing": "cdn-cache;desc=HIT, intid;desc=\(backendTracingID), edge;dur=1"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        AssertEqualAndNotNil(sut, backendTracingID)
    }

    func test_backendTracingID_multiple_backendTracingIDs() {
        // Given
        let backendTracingID1 = "d2f7aebc1ee0813c"
        let backendTracingID2 = "anotherID"
        let headerFields = ["server-timing": "cdn-cache;desc=HIT, intid;desc=\(backendTracingID1), edge;dur=1, intid;desc=\(backendTracingID2)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        AssertEqualAndNotNil(sut, backendTracingID2)
    }

    func test_backendTracingID_missing() {
        // Given
        let backendTracingID = ""
        let headerFields = ["Server-Timing": "intid;desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        XCTAssertNil(sut)
    }

    func test_backendTracingID_broken() {
        // Given
        let backendTracingID = "someID"
        let headerFields = ["Server-Timing": "invalid_desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        XCTAssertNil(sut)
    }

    func test_backendTracingID_broken_2() {
        // Given
        let backendTracingID = "someID"
        let headerFields = ["ServerTiming": "intid;desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        XCTAssertNil(sut)
    }
}
