//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class DoublePlusMiscTests: InstanaTestCase {

    // MARK: - != operator

    func test_notEqual_whenDifferenceExceedsThreshold_shouldReturnTrue() {
        // Given
        let lhs: Double = 1.0
        let rhs: Double = 2.0

        // When / Then
        XCTAssertTrue(lhs != rhs)
    }

    func test_notEqual_whenValuesAreIdentical_shouldReturnFalse() {
        // Given
        let lhs: Double = 3.14159
        let rhs: Double = 3.14159

        // When / Then
        XCTAssertFalse(lhs != rhs)
    }

    func test_notEqual_whenDifferenceIsExactlyThreshold_shouldReturnFalse() {
        // Given – difference of exactly 0.000001 is NOT greater than the threshold,
        // so == returns true and != must return false.
        let lhs: Double = 1.000001
        let rhs: Double = 1.000000

        // When / Then
        XCTAssertFalse(lhs != rhs)
    }

    func test_notEqual_whenDifferenceIsJustAboveThreshold_shouldReturnTrue() {
        // Given – difference slightly above 0.000001
        let lhs: Double = 1.0000011
        let rhs: Double = 1.0000000

        // When / Then
        XCTAssertTrue(lhs != rhs)
    }

    func test_notEqual_whenBothValuesAreZero_shouldReturnFalse() {
        // Given
        let lhs: Double = 0.0
        let rhs: Double = 0.0

        // When / Then
        XCTAssertFalse(lhs != rhs)
    }

    func test_notEqual_whenBothValuesAreNegativeAndEqual_shouldReturnFalse() {
        // Given
        let lhs: Double = -5.5
        let rhs: Double = -5.5

        // When / Then
        XCTAssertFalse(lhs != rhs)
    }

    func test_notEqual_whenNegativeAndPositiveWithSameMagnitude_shouldReturnTrue() {
        // Given
        let lhs: Double = -1.0
        let rhs: Double = 1.0

        // When / Then
        XCTAssertTrue(lhs != rhs)
    }

    func test_notEqual_isCommutative() {
        // Given
        let lhs: Double = 10.5
        let rhs: Double = 20.5

        // When / Then – order should not matter
        XCTAssertEqual(lhs != rhs, rhs != lhs)
    }

    func test_notEqual_whenVeryLargeValuesWithSmallDifference_shouldReturnTrue() {
        // Given
        let lhs: Double = 1_000_000.000002
        let rhs: Double = 1_000_000.000000

        // When / Then – difference of 0.000002 > threshold
        XCTAssertTrue(lhs != rhs)
    }

    func test_notEqual_consistentWithEqualOperator() {
        // Given
        let pairs: [(Double, Double)] = [
            (0.0, 0.0),
            (1.0, 2.0),
            (3.14, 3.14),
            (-7.0, -7.0),
            (0.5, 0.500002),
        ]

        // When / Then – != must always be the logical negation of ==
        for (lhs, rhs) in pairs {
            XCTAssertEqual(lhs != rhs, !(lhs == rhs),
                           "Inconsistency detected for lhs=\(lhs), rhs=\(rhs)")
        }
    }
}
