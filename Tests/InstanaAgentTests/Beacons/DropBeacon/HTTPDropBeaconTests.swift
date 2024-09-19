
import XCTest
@testable import InstanaAgent

class HTTPDropBeaconTests: InstanaTestCase {
    func test_all() {
        // Given
        let url = "https://www.ibm.com"
        let view = "testViewName"
        let statusCode = 200
        let method = "GET"
        let headers = ["key2": "value2", "key3": "value3", "key1": "value1"]
        let dropBeacon = HTTPDropBeacon(timestamp: Date().millisecondsSince1970,
                                        url: url, hsStatusCode: "\(statusCode)",
                                        view: view, hmMethod: method,
                                        headers: headers)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        let headerStr = dropBeacon.dictionaryToJsonString(headers) ?? ""
        AssertEqualAndNotNil(result1, "\(url)|\(view)|\(method)|\(statusCode)|\(headerStr)")
        AssertEqualAndNotNil(result2!,"{\"count\":\(dropBeacon.count),\"type\":\"HTTP\",\"zInfo\":{\"headers\":{\"key1\":\"value1\",\"key2\":\"value2\",\"key3\":\"value3\"},\"hm\":\"\(method)\",\"hs\":\"\(statusCode)\",\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"url\":\"https:\\/\\/www.ibm.com\",\"view\":\"\(view)\"}}")
    }

    func test_negatives() {
        // Given
        let url: String? = nil
        let view: String? = nil
        let statusCode: String? = nil
        let method: String? = nil
        let headers: [String: String]? = nil
        let dropBeacon = HTTPDropBeacon(timestamp: Date().millisecondsSince1970, url: url,
                                        hsStatusCode: statusCode, view: view, hmMethod: method, headers: headers)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        AssertEqualAndNotNil(result1, "||||")
        AssertEqualAndNotNil(result2!, "{\"count\":\(dropBeacon.count),\"type\":\"HTTP\",\"zInfo\":{\"headers\":{},\"hm\":\"\",\"hs\":\"\",\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"url\":\"\",\"view\":\"\"}}")
    }
}
