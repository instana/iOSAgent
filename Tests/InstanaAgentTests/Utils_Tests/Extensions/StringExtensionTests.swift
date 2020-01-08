import Foundation
import XCTest
@testable import InstanaAgent

class StringExtensionTests: XCTestCase {

    func test_truncate() {
        // Given
        let longString = (0...50).map {"\($0)"}.joined()

        // When
        let sut = longString.truncated(at: 10, trailing: ".....")

        // Then
        AssertTrue(sut == "0123456789.....")
    }

    func test_truncate_no_trailing_Dots() {
        // Given
        let longString = (0...50).map {"\($0)"}.joined()

        // When
        let sut = longString.truncated(at: 10, trailing: "")

        // Then
        AssertTrue(sut == "0123456789")
    }
}
