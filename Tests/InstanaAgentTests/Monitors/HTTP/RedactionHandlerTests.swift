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

    func test_queryTrackedDomainList_urlInList() {
        // Given
        let redactionHandler = RedactionHandler.default
        let queryTrackedDomainList: [NSRegularExpression] = [
            try! NSRegularExpression(pattern: "https://www.ibm.com")
        ]
        redactionHandler.setQueryTrackedDomainList(regex: queryTrackedDomainList)
        let url = URL(string: "https://www.ibm.com/en-us?password=pass#fragment1")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.ibm.com/en-us?password=%3Credacted%3E#fragment1")!)
    }

    func test_queryTrackedDomainList_urlNotInList() {
        // Given
        let redactionHandler = RedactionHandler.default
        let queryTrackedDomainList: [NSRegularExpression] = [
            try! NSRegularExpression(pattern: "https://www.ibm.com")
        ]
        redactionHandler.setQueryTrackedDomainList(regex: queryTrackedDomainList)
        let url = URL(string: "https://www.example.com/en-us?password=pass#fragment2")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.example.com/en-us")!)
    }

    func test_queryTrackedDomainList_notConfigured() {
        // Given
        let redactionHandler = RedactionHandler.default
        let url = URL(string: "https://www.ibm.com/en-us?password=pass#fragment3")!

        // When
        let redacted = redactionHandler.redact(url: url)

        // Then
        XCTAssertEqual(redacted, URL(string: "https://www.ibm.com/en-us?password=%3Credacted%3E#fragment3")!)
    }
}
