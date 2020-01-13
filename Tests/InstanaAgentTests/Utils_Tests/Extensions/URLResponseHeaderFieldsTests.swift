import XCTest
import Foundation
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
        let backendTracingID = ""
        let headerFields = ["Server-Timing": "invalid_desc=\(backendTracingID)"]
        let httpResponse = HTTPURLResponse(url: URL.random, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)

        // When
        let sut = httpResponse?.backendTracingID

        // Then
        XCTAssertNil(sut)
    }
}
