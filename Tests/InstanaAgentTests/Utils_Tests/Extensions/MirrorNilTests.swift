import Foundation
import XCTest
@testable import InstanaAgent

class MirrorNilTests: InstanaTestCase {

    func test_nonNilChildren() {
        // Given
        struct SomeModel {
            var id: String = "ID"
            var name: String? = "Name"
            var age: Int?
        }
        let sut = SomeModel()

        // When
        let nonNilValues = Array(Mirror(reflecting: sut).nonNilChildren)

        // Then
        AssertEqualAndNotZero(nonNilValues.count, 2)
        AssertEqualAndNotNil(nonNilValues.first?.label, "id")
        AssertEqualAndNotNil(nonNilValues.first?.value as? String, "ID")
        AssertEqualAndNotNil(nonNilValues.last?.label, "name")
        AssertEqualAndNotNil(nonNilValues.last?.value as? String, "Name")
    }

    func test_Any_Is_Nil() {
        // Given
        let name: String? = nil

        // When
        let sut = Mirror.isNotNil(value: name as Any)

        // Then
        AssertTrue(sut == false)
    }

    func test_Any_Is_NOT_Nil() {
        // Given
        let name: String? = "Hallo"

        // When
        let sut = Mirror.isNotNil(value: name as Any)

        // Then
        AssertTrue(sut)
    }
}
