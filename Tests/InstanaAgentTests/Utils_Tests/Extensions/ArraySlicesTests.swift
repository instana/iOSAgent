import Foundation
import XCTest
@testable import InstanaAgent

class ArraySlicesTests: InstanaTestCase {

    let maxItems = 100

    func test_slice_length99() {
        // Given
        let list = (1...99).map { "\($0)" }

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, list)
    }

    func test_slice_length100() {
        // Given
        let list = (1...100).map { "\($0)" }

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, list)
    }

    func test_slice_length101() {
        // Given
        let list = (1...101).map { "\($0)" }

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.first?.count, maxItems)
        XCTAssertEqual(sut.last?.count, list.count % maxItems)
        XCTAssertEqual(sut.first, Array(list[0..<maxItems]))
        XCTAssertEqual(sut.last, [list.last!])
    }

    func test_slice_length199() {
        // Given
        let list = (1...199).map { "\($0)" }

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 2)
        XCTAssertEqual(sut.first?.count, maxItems)
        XCTAssertEqual(sut.last?.count, list.count % maxItems)
        XCTAssertEqual(sut.first, Array(list[0..<maxItems]))
        XCTAssertEqual(sut.last, Array(list[100..<list.count]))
    }

    func test_slice_length250() {
        // Given
        let list = (1..<250).map { "\($0)" }

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 3)
        XCTAssertEqual(sut[1], Array(list[100..<200]))
        XCTAssertEqual(sut.last, Array(list[200..<list.count]))
    }

    func test_slice_length0() {
        // Given
        let list = [String]()

        // When
        let sut = list.chunked(size: maxItems)

        // Then
        XCTAssertEqual(sut.count, 0)
    }

    func test_slice_length5_chunkSize_1() {
        // Given
        let list = (1...5).map { "\($0)" }

        // When
        let sut = list.chunked(size: 1)

        // Then
        XCTAssertEqual(sut[0][0], "1")
        XCTAssertEqual(sut[1][0], "2")
        XCTAssertEqual(sut[2][0], "3")
        XCTAssertEqual(sut[3][0], "4")
        XCTAssertEqual(sut[4][0], "5")
    }
}
