import XCTest
@testable import InstanaAgent

class RedactionHandlerTests: InstanaTestCase {

    func test_redact_default() {
        // Given
        let redactionHandler = RedactionHandler.default
        let url = URL(string: "https://www.instana.com/one/?secret=secret&Password=test&KEY=123&aKey=123&myPassword=sec")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.instana.com/one/?secret=redacted&Password=redacted&KEY=redacted&aKey=redacted&myPassword=redacted")!)
    }

    func test_redact_own_regex() {
        // Given
        let regex = try! NSRegularExpression(pattern: #"(?<=password=)[^&]+"#, options: [.caseInsensitive])
        let redactionHandler = RedactionHandler(regex: [regex])
        let url = URL(string: "https://www.instana.com/one/?thePassword=secret&Password=test&PasSword=123")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.instana.com/one/?thePassword=redacted&Password=redacted&PasSword=redacted")!)
    }
}
