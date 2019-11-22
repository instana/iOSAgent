//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaEventTests: XCTestCase {

    func test_eventData_shouldBeSerializedToJSON() {
        let event = InstanaEvent(sessionId: "a", eventId: "b", timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": "a",
            "id": "b"
        ])
    }
    
    func test_nilEventID_shouldNotFallBackToDefault() {
        let event = InstanaEvent(eventId: nil, timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.shouldBeNil
        ])
    }
    
    func test_eventDefaultParameters() {
        let event = InstanaEvent(timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString
        ])
    }
}
