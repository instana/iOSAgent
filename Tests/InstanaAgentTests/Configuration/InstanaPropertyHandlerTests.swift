import XCTest
import Foundation
@testable import InstanaAgent

class InstanaPropertyHandlerTests: InstanaTestCase {

    func test_maximumNumberOfMetaDataFields() {
        AssertEqualAndNotZero(InstanaPropertyHandler.Const.maximumNumberOfMetaDataFields, 50)
    }

    func test_maximumLengthPerMetaDataField() {
        AssertEqualAndNotZero(InstanaPropertyHandler.Const.maximumLengthPerMetaDataField, 256)
    }

    func test_validate_keys_valid() {
        // Given
        let keys = (0..<InstanaPropertyHandler.Const.maximumNumberOfMetaDataFields).map { "key \($0)" }
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = propertyHandler.validate(keys: keys)

        // Then
        AssertTrue(sut)
    }

    func test_validate_keys_invalid() {
        // Given
        let keys = (0...InstanaPropertyHandler.Const.maximumNumberOfMetaDataFields).map { "key \($0)" }
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = propertyHandler.validate(keys: keys)

        // Then
        AssertTrue(sut == false)
    }

    func test_validate_value_valid() {
        // Given
        let length = InstanaPropertyHandler.Const.maximumLengthPerMetaDataField
        let value = createString(length)
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = propertyHandler.validate(value: value)

        // Then
        AssertTrue(sut)
    }

    func test_validate_value_invalid() {
        // Given
        let length = InstanaPropertyHandler.Const.maximumLengthPerMetaDataField
        let value = createString(length + 1)
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = propertyHandler.validate(value: value)

        // Then
        AssertTrue(sut == false)
    }

    // Helper
    func createString(_ length: Int) -> String {
        String((0...length).map { "\($0)" }.joined().suffix(length))
    }
}
