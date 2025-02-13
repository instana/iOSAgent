
import XCTest
@testable import InstanaAgent

class ViewDropBeaconTests: InstanaTestCase {
    func test_all() {
        // Given
        let viewName = "testViewName"
        let imMap = ["key2": "value2", "key3": "value3", "key1": "value1"]
        let dropBeacon = ViewDropBeacon(timestamp: Date().millisecondsSince1970,
                                        viewName: viewName, imMap: imMap)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        let imMapStr = dropBeacon.dictionaryToJsonString(imMap) ?? ""
        AssertEqualAndNotNil(result1, "\(viewName)|\(imMapStr)")
        let expected = "{\"count\":\(dropBeacon.count),\"type\":\"viewChange\",\"zInfo\":{\"im_\":{\"key1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"},\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"v\":\"\(viewName)\"}}"
        AssertEqualAndNotNil(result2!, expected)
    }

    func test_negatives() {
        // Given
        let viewName: String? = nil
        let imMap: [String: String]? = nil
        let dropBeacon = ViewDropBeacon(timestamp: Date().millisecondsSince1970,
                                        viewName: viewName, imMap: imMap)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        AssertEqualAndNotNil(result1, "|")
        AssertEqualAndNotNil(result2!, "{\"count\":\(dropBeacon.count),\"type\":\"viewChange\",\"zInfo\":{\"im_\":{},\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"v\":\"\"}}")
    }
}
