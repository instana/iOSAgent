//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class AlertEventTests: XCTestCase {

    func test_alertANREventValues_shouldBeSerializedToJSON() {
        let event = AlertEvent(alertType: .anr(duration: 1.5), screen: "a")
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString,
            "alert": [
                "timestamp": ComparisonType.greaterThanZero,
                "anr": [
                    "screen": "a",
                    "durationMs": 1500.0
                ]
            ]
        ])
    }
    
    func test_alertLowMemoryEventValues_shouldBeSerializedToJSON() {
        let event = AlertEvent(alertType: .lowMemory, screen: "b")
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString,
            "alert": [
                "timestamp": ComparisonType.greaterThanZero,
                "lowMemory": [
                    "screen": "b",
                ]
            ]
        ])
    }
    
    func test_alertFramerateDropValues_shouldBeSerializedToJSON() {
        let event = AlertEvent(alertType: .framerateDrop(duration: 2, averageFramerate: 10), screen: "c")
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString,
            "alert": [
                "timestamp": ComparisonType.greaterThanZero,
                "framerateDrop": [
                    "screen": "c",
                    "durationMs": 2000.0,
                    "averageFramerate": 10 as Float
                ]
            ]
        ])
    }
}
