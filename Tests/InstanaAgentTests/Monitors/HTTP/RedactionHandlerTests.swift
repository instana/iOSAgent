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
        XCTAssertEqual(redacted, URL(string: "https://www.instana.com/one/?secret=%3Credacted%3E&Password=%3Credacted%3E&KEY=%3Credacted%3E&aKey=%3Credacted%3E&myPassword=%3Credacted%3E")!)
    }

    func test_redact_own_regex() {
        // Given
        let regex = try! NSRegularExpression(pattern: #"pass(word|wort)"#, options: [.caseInsensitive])
        let redactionHandler = RedactionHandler(regex: [regex])
        let url = URL(string: "https://www.instana.com/one/?thePassword=secret&Passwort=test&PasSword=123")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.instana.com/one/?thePassword=%3Credacted%3E&Passwort=%3Credacted%3E&PasSword=%3Credacted%3E")!)
    }
}
