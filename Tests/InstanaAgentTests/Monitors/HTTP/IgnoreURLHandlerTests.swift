import XCTest
@testable import InstanaAgent

class IgnoreURLHandlerTests: XCTestCase {

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
        IgnoreURLHandler.regexPatterns = []
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
        IgnoreURLHandler.regexPatterns = [".*(&|\\?)password=.*"]

        // When
        let sut = IgnoreURLHandler.shouldIgnore(URL(string: "http://www.example.com/?password=Key")!)

        // Then
        AssertTrue(sut)
    }
}
