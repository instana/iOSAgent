//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class EventTests: XCTestCase {

    func test_eventData_shouldBeSerializedToJSON() {
        let event = Event(sessionId: "a", eventId: "b", timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": "a",
            "id": "b"
        ])
    }
    
    func test_nilEventID_shouldNotFallBackToDefault() {
        let event = Event(eventId: nil, timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.shouldBeNil
        ])
    }
    
    func test_eventDefaultParameters() {
        let event = Event(timestamp: 0)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString
        ])
    }
}
