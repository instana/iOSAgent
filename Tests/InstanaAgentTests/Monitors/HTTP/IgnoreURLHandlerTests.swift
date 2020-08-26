import XCTest
@testable import InstanaAgent

class IgnoreURLHandlerTests: InstanaTestCase {

    func test_ignore_exact_URL() {
        // Given
        IgnoreURLHandler.exactURLs = [URL(string: "http://www.example.com")!]

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com")!)

        // Then
        AssertTrue(sut)
    }

    func test_not_ignoring_exact_URL() {
        // Given
        IgnoreURLHandler.exactURLs = [URL(string: "http://www.example.com/some")!]

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com")!)

        // Then
        AssertTrue(sut == false)
    }

    func test_empty_ignore() {
        // Given
        IgnoreURLHandler.regex = []
        IgnoreURLHandler.exactURLs = []

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com/start?secret=Key")!)

        // Then
        AssertTrue(sut == false)
    }

    func test_not_ignoring_exact_URL_2() {
        // Given
        IgnoreURLHandler.exactURLs = [URL(string: "http://www.example.com")!]

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com/some")!)

        // Then
        AssertTrue(sut == false)
    }

    func test_ignore_regex_pattern() {
        // Given
        let regex = try! NSRegularExpression(pattern: ".*(&|\\?)password=.*")
        IgnoreURLHandler.regex = [regex]

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com/?password=Key")!)

        // Then
        AssertTrue(sut)
    }

    func test_loadDefaultDefaultIgnoredURLs() {
        // Given
        let url = session.configuration.reportingURL

        // When
        IgnoreURLHandler.loadDefaultDefaultIgnoredURLs(session: session!)

        // Then
        AssertTrue(IgnoreURLHandler.shouldIgnore(url))
        AssertTrue(IgnoreURLHandler.shouldIgnore(URL(string: "https://api.instabug.com/some")!))
        AssertTrue(IgnoreURLHandler.shouldIgnore(URL(string: "https://some.instabug.com/some")!))
        AssertFalse(IgnoreURLHandler.shouldIgnore(URL(string: "https://some.instabug.de/some")!))
    }
}

class DefaultIgnoredURLsTests: XCTestCase {

    func test_excludedURLs() {
        // Nothing specific yet
        AssertEqualAndNotNil(DefaultIgnoredURLs.excludedURLs, [])
    }

    func test_excludedPatterns() {
        AssertEqualAndNotNil(DefaultIgnoredURLs.excludedPatterns, [".*instabug.com.*"])
    }
}
