//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class StringExtensionTests: InstanaTestCase {

    func test_truncate() {
        // Given
        let longString = (0...50).map {"\($0)"}.joined()

        // When
        let sut = longString.maxLength(10, trailing: ".....")

        // Then
        AssertEqualAndNotNil(sut, "01234.....")
    }

    func test_truncate_no_trailing_Dots() {
        // Given
        let longString = (0...50).map {"\($0)"}.joined()

        // When
        let sut = longString.maxLength(10, trailing: "")

        // Then
        AssertTrue(sut == "0123456789")
    }

    func test_clean_and_escape() {
        XCTAssertEqual("Some\nNewline\tTab\\escape".cleanEscape(), "Some\\nNewline\\tTab\\\\escape")
        XCTAssertEqual("Some\nNewline\tTab\\escape".coreBeaconClean(), "Some\\nNewline\\tTab\\\\escape")
    }

    func test_clean_remove_newline() {
        XCTAssertEqual("\n".cleanEscape(), "")
        XCTAssertEqual("\n".coreBeaconClean(), "")
    }

    func test_clean_remove_newline_2() {
        XCTAssertEqual("\nTest".cleanEscape(), "Test")
        XCTAssertEqual("\nTest".coreBeaconClean(), "Test")
    }

    func test_clean_remove_tab() {
        XCTAssertEqual("\t".cleanEscape(), "")
        XCTAssertEqual("\t".coreBeaconClean(), "")
    }

    func test_clean_remove_whitespace() {
        XCTAssertEqual(" ".cleanEscape(), "")
        XCTAssertEqual(" ".coreBeaconClean(), "")
    }

    func test_truncate_default() {
        XCTAssertEqual("ABCD".maxLength(3), "AB…")
    }

    func test_truncate_custom_trailing() {
        XCTAssertEqual("ABCD".maxLength(3, trailing: ">>"), "A>>")
    }

    func test_truncate_corebeacon() {
        let given = (0...CoreBeacon.maxLengthPerField).map {_ in "A"}.joined()
        let expected = String(given.prefix(CoreBeacon.maxLengthPerField-1)) + "…"
        XCTAssertEqual(given.coreBeaconClean(), expected)
    }
}
