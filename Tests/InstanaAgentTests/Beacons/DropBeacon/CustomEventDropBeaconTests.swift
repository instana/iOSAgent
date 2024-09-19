
import XCTest
@testable import InstanaAgent

class CustomEventDropBeaconTests: InstanaTestCase {
    func test_all() {
        // Given
        let eventName = "test custom event"
        let view = "test view name"
        let errorCount = 1
        let errorMessage = "test error message"
        let customMetric = "0"
        let dropBeacon = CustomEventDropBeacon(timestamp: Date().millisecondsSince1970, eventName:eventName, view: view,
                                               errorCount: errorCount, errorMessage: errorMessage, customMetric: customMetric)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        AssertEqualAndNotNil(result1, "\(eventName)|\(errorMessage)|\(errorCount)|\(view)")
        let expected = "{\"count\":\(dropBeacon.count),\"type\":\"CUSTOM_EVENT\",\"zInfo\":{\"customMetric\":\"0\",\"errorCount\":1,\"errorMessage\":\"test error message\",\"eventName\":\"\(eventName)\",\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"view\":\"\(view)\"}}"
        AssertEqualAndNotNil(result2, expected)
    }

    func test_negatives() {
        // Given
        let eventName = "test custom event"
        let view: String? = nil
        let errorCount: Int? = nil
        let errorMessage: String? = nil
        let customMetric: String? = nil
        let dropBeacon = CustomEventDropBeacon(timestamp: Date().millisecondsSince1970, eventName:eventName, view: view,
                                               errorCount: errorCount, errorMessage: errorMessage, customMetric: customMetric)

        // When
        let result1 = dropBeacon.getKey()
        let result2 = dropBeacon.toString()

        // Then
        AssertEqualAndNotNil(result1, "\(eventName)||0|")
        let expected = "{\"count\":\(dropBeacon.count),\"type\":\"CUSTOM_EVENT\",\"zInfo\":{\"customMetric\":\"\",\"errorCount\":0,\"errorMessage\":\"\",\"eventName\":\"\(eventName)\",\"tMax\":\(dropBeacon.timeMax),\"tMin\":\(dropBeacon.timeMin),\"view\":\"\"}}"
        AssertEqualAndNotNil(result2, expected)
    }
}
