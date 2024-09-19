
import XCTest
@testable import InstanaAgent

class DropBeaconTests: InstanaTestCase {
    func test_init() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let dropBeacon = DropBeacon(timestamp: timestamp)

        // Then
        AssertEqualAndNotNil(dropBeacon.count, 1)
        AssertEqualAndNotNil(dropBeacon.timeMin, timestamp)
        AssertEqualAndNotNil(dropBeacon.timeMax, timestamp)
    }

    func test_placeholder_methods() {
        // Given
        let dropBeacon = DropBeacon(timestamp: Date().millisecondsSince1970)

        // Then
        AssertEqualAndNotNil(dropBeacon.getKey(), "dropBeaconPlaceholderKey")
        AssertTrue(dropBeacon.toString() == nil)
    }

    func test_dictionaryToJsonString() {
        // Given
        let dropBeacon = DropBeacon(timestamp: Date().millisecondsSince1970)

        // When
        let dict = ["key2": "value2", "key3": "value3", "key1": "value1"]
        let result = dropBeacon.dictionaryToJsonString(dict)

        // Then
        AssertEqualAndNotNil(result, "{\"key1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"}")
    }

    func test_validateLength() {
        // Given
        let dropBeacon = DropBeacon(timestamp: Date().millisecondsSince1970)

        // When
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let result1 = dropBeacon.validateLength(chars)

        let longStr = String(repeating: chars, count: 20)
        let result2 = dropBeacon.validateLength(longStr)

        // Then
        AssertEqualAndNotNil(result1.count, chars.count)
        AssertEqualAndNotNil(result2.count, 1024)
    }
}
