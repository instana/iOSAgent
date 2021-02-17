//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaPropertyHandlerTests: InstanaTestCase {

    func test_maxNumberOfMetaEntries() {
        AssertEqualAndNotZero(MetaData.Max.numberOfMetaEntries, 64)
    }

    func test_maxLengthMetaValue() {
        AssertEqualAndNotZero(MetaData.Max.lengthMetaValue, 256)
    }

    func test_maxLengthMetaKey() {
        AssertEqualAndNotZero(MetaData.Max.lengthMetaKey, 98)
    }

    func test_validate_keys_valid() {
        // Given
        let max = MetaData.Max.numberOfMetaEntries
        let keys = (0..<max).map { "key \($0)" }
        let values = (0..<max).map { "value \($0)" }
        var properties = InstanaProperties()

        // When
        (0..<max).forEach {index in
            properties.appendMetaData(keys[index], values[index])
        }

        // Then
        AssertTrue(properties.metaData.keys.count == max)
        AssertTrue(properties.metaData.values.count == max)
    }

    func test_validate_keys_one_overflow() {
        // Given
        let max = MetaData.Max.numberOfMetaEntries
        let keys = (0...max).map { "key \($0)" }
        let values = (0...max).map { "value \($0)" }
        var properties = InstanaProperties()

        // When
        (0..<max).forEach {index in
            properties.appendMetaData(keys[index], values[index])
        }

        // Then
        AssertTrue(properties.metaData.keys.count == keys.count - 1)
        AssertTrue(properties.metaData.keys.count == max)
    }

    func test_validate_value_valid() {
        // Given
        let length = MetaData.Max.lengthMetaValue
        let value = createString(length)

        // When
        let sut = MetaData.validate(value: value)

        // Then
        AssertEqualAndNotNil(sut, value)
    }

    func test_validate_value_invalid() {
        // Given
        let length = MetaData.Max.lengthMetaValue
        let value = createString(length + 1)

        // When
        let sut = MetaData.validate(value: value)

        // Then
        AssertEqualAndNotNil(sut, sut.cleanEscapeAndTruncate(at: length))
    }

    // Helper
    func createString(_ length: Int) -> String {
        String((0...length).map { "\($0)" }.joined().suffix(length))
    }
}

class InstanaPropertiesTests: XCTestCase {

    func test_appendMetaData() {
        // Given
        var properties = InstanaProperties()

        // When
        properties.appendMetaData("Key", "Value")

        // Then
        XCTAssertEqual(properties.metaData["Key"], "Value")
        XCTAssertTrue(properties.metaData.count == 1)
    }

    func test_appendMetaData_exceeds_length() {
        // Given
        let key = (0...MetaData.Max.lengthMetaKey).map {_ in "K" }.joined()
        let value = (0...MetaData.Max.lengthMetaValue).map {_ in "V" }.joined()

        var properties = InstanaProperties()

        // When
        properties.appendMetaData(key, value)

        // Then
        let expectedKey = key.cleanEscapeAndTruncate(at: key.count - 1)
        let expectedValue = value.cleanEscapeAndTruncate(at: value.count - 1)
        XCTAssertEqual(properties.metaData[expectedKey], expectedValue)
        XCTAssertEqual(properties.metaData[expectedKey]?.last, "…")
        XCTAssertTrue(properties.metaData.count == 1)
    }

    func test_view_valid_length() {
        // Given
        let maxLength = InstanaProperties.viewMaxLength
        let view = (0..<maxLength).map {_ in "V" }.joined()
        var properties = InstanaProperties()

        // When
        properties.view = view

        // Then
        XCTAssertEqual(properties.view?.last, "V")
        XCTAssertEqual(properties.view?.count, maxLength)
    }

    func test_view_exceeds_length() {
        // Given
        let maxLength = InstanaProperties.viewMaxLength
        let view = (0...maxLength).map {_ in "V" }.joined()

        // When
        let properties = InstanaProperties(user: nil, view: view)

        // Then
        XCTAssertEqual(maxLength, 256)
        XCTAssertEqual(properties.view?.last, "…")
        XCTAssertEqual(properties.view?.count, maxLength)
    }

    func test_view_exceeds_length_via_setter() {
        // Given
        let maxLength = InstanaProperties.viewMaxLength
        let view = (0...maxLength).map {_ in "V" }.joined()
        var properties = InstanaProperties()

        // When
        properties.view = view

        // Then
        XCTAssertEqual(maxLength, 256)
        XCTAssertEqual(properties.view?.last, "…")
        XCTAssertEqual(properties.view?.count, maxLength)
    }

    func test_user_valid_length() {
        // Given
        let maxLength = InstanaProperties.User.userValueMaxLength
        let value = (0..<maxLength).map {_ in "U" }.joined()

        // When
        let user = InstanaProperties.User(id: value, email: value, name: value)

        // Then
        XCTAssertEqual(user.id.last, "U")
        XCTAssertEqual(user.email?.last, "U")
        XCTAssertEqual(user.name?.last, "U")
        XCTAssertEqual(user.id.count, maxLength)
        XCTAssertEqual(user.email?.count, maxLength)
        XCTAssertEqual(user.name?.count, maxLength)
    }

    func test_user_exceeds_length() {
        // Given
        let maxLength = InstanaProperties.User.userValueMaxLength
        let value = (0...maxLength).map {_ in "U" }.joined()

        // When
        let user = InstanaProperties.User(id: value, email: value, name: value)

        // Then
        XCTAssertEqual(maxLength, 128)
        XCTAssertEqual(user.id.last, "…")
        XCTAssertEqual(user.email?.last, "…")
        XCTAssertEqual(user.name?.last, "…")
        XCTAssertEqual(user.id.count, maxLength)
        XCTAssertEqual(user.email?.count, maxLength)
        XCTAssertEqual(user.name?.count, maxLength)
    }

    func test_user_exceeds_length_via_setter() {
        // Given
        let maxLength = InstanaProperties.User.userValueMaxLength
        let value = (0...maxLength).map {_ in "U" }.joined()

        // When
        var user = InstanaProperties.User(id: "1", email: "2", name: "3")
        user.id = value
        user.email = value
        user.name = value

        // Then
        XCTAssertEqual(maxLength, 128)
        XCTAssertEqual(user.id.last, "…")
        XCTAssertEqual(user.email?.last, "…")
        XCTAssertEqual(user.name?.last, "…")
        XCTAssertEqual(user.id.count, maxLength)
        XCTAssertEqual(user.email?.count, maxLength)
        XCTAssertEqual(user.name?.count, maxLength)
    }
}

