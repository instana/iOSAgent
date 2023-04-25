//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class AtomicTests: InstanaTestCase {
    func test_AtomicDictionary_subscript() {
        // Given
        let dict = AtomicDictionary<String, Int>()

        // When
        dict["aaa"] = 100

        // Then
        XCTAssertEqual(dict["aaa"], 100)
    }

    func test_AtomicDictionary_debugDescription() {
        // Given
        let dict = AtomicDictionary<Int, String>()

        // When
        dict[100] = "bbb"

        // Then
        XCTAssertEqual(dict.debugDescription, "[100: \"bbb\"]")
    }

    func test_AtomicDictionary_Equatable() {
        // Given
        let dict1 = AtomicDictionary<String, String>()
        dict1["ccc"] = "ddd"

        let dict2 = AtomicDictionary<String, String>()
        dict2["ccc"] = "ddd"

        // Then
        XCTAssertTrue(dict1 == dict2)

        // When
        dict1["ccc"] = "eee"
        // Then
        XCTAssertFalse(dict1 == dict2)
    }

    func test_AtomicArray_startEndIndex() {
        // test 1, empty array
        // Given
        let arr = AtomicArray<Int>()

        // Then
        XCTAssertEqual(arr.startIndex, 0)
        XCTAssertEqual(arr.endIndex, 0)

        // test 2
        // When
        arr.append(444)

        // Then
        XCTAssertEqual(arr.startIndex, 0)
        XCTAssertEqual(arr.endIndex, 1)
    }

    func test_AtomicArray_subscript() {
        // Given
        let arr = AtomicArray<Int>()
        arr.append(33)

        // When
        arr[0] = 44

        // Then
        XCTAssertEqual(arr[0], 44)
    }

    func test_AtomicArray_debugDescription() {
        // Given
        let arr = AtomicArray<Int>()

        // Then
        XCTAssertEqual(arr.debugDescription, "[]")
    }

    func test_AtomicArray_index() {
        // Given
        let arr = AtomicArray<Int>()

        // When
        arr.append(55)

        // Then
        XCTAssertEqual(arr.index(before: 0), -1)
        XCTAssertEqual(arr.index(after: 0), 1)
    }

    func test_AtomicArray_removeAll() {
        // Given
        let arr = AtomicArray<Double>()
        arr.append(88.8)
        arr.append(99.9)
        arr.append(88.8)
        XCTAssertEqual(arr.count, 3)

        // When
        arr.removeAll(where: { $0 == 88.8})

        // Then
        XCTAssertEqual(arr.count, 1)
    }

    func test_AtomicArray_contains() {
        // Given
        let arr = AtomicArray<Int>()

        // When
        arr.append(66)

        // Then
        XCTAssertTrue(arr.contains(66))
        XCTAssertFalse(arr.contains(77))
    }

    func test_AtomicArray_Equatable() {
        // Given
        let arr1 = AtomicArray<Int>()
        arr1.append(123)

        let arr2 = AtomicArray<Int>()
        arr2.append(123)

        // Then
        XCTAssertTrue(arr1 == arr2)

        // When
        arr2.append(123)
        // Then
        XCTAssertFalse(arr1 == arr2)
    }
}
