//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaCustomEventTests: XCTestCase {

    func test_customEventValues_shouldBeSerializedToJSON() {
        let event = InstanaCustomEvent(name: "my-event", timestamp: 123, duration: 321)
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": ComparisonType.nonEmptyString,
            "event": [
                "timestamp": 123.0,
                "durationMs": 321.0,
                "customEvent": [
                    "name": "my-event"
                ]
            ]
        ])
    }
}
