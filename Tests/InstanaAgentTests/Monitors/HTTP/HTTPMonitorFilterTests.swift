import XCTest
@testable import InstanaAgent

class HTTPMonitorFilterTests: InstanaTestCase {

    func test_redact_url() {
        // Given
        let url = URL.random
        let redactionHandler = MockRedactionHandler(regex: [])
        let filter = HTTPMonitorFilter(redactionHandler: redactionHandler)

        // When
        let sut = filter.redact(url: url)

        // Then
        AssertEqualAndNotNil(url, redactionHandler.didCallRedactURL)
        AssertEqualAndNotNil(url, sut)
    }

    func test_setRedaction() {
        // Given
        let regex = [try! NSRegularExpression(pattern: "some")]
        let redactionHandler = RedactionHandler(regex: [])
        let filter = HTTPMonitorFilter(redactionHandler: redactionHandler)

        // When
        filter.setRedaction(regex: regex)

        // Then
        AssertEqualAndNotNil(redactionHandler.regex, Set(regex))
    }

    func test_filterHeaderFields_none() {
        // Given
        let header = ["Key": "Value"]
        let filter = HTTPMonitorFilter()

        // When
        let sut = filter.filterHeaderFields(header)!

        // Then
        XCTAssertTrue(sut.isEmpty)
    }

    func test_filterHeaderFields_one_matching() {
        // Given
        let header = ["Key": "Value", "More": "Values"]
        let regex = try! NSRegularExpression(pattern: "key", options: .caseInsensitive)
        let filter = HTTPMonitorFilter()

        // When
        filter.headerFieldsRegEx = [regex]
        let sut = filter.filterHeaderFields(header)!

        // Then
        AssertEqualAndNotNil(sut["Key"], "Value")
        XCTAssertTrue(sut.count == 1)
    }

    func test_filterHeaderFields_caseSensitive() {
        // Given
        let header = ["Key": "Value", "key": "new"]
        let regex = try! NSRegularExpression(pattern: "key")
        let filter = HTTPMonitorFilter()

        // When
        filter.headerFieldsRegEx = [regex]
        let sut = filter.filterHeaderFields(header)!

        // Then
        AssertEqualAndNotNil(sut["key"], "new")
        XCTAssertTrue(sut.count == 1)
    }
}
