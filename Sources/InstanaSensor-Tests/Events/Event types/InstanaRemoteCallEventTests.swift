//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import iOSSensor

class InstanaRemoteCallEventTests: XCTestCase {

    func test_remoteCallEventValues_shouldBeSerializedToJSON() {
        let event = InstanaRemoteCallEvent(eventId: "a", timestamp: 123, duration: 45, method: "METHOD", url: "URL", connectionType: .wifi, responseCode: 321, requestSize: 11, responseSize: 22, result: "res")
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": "a",
            "event": [
                "timestamp": 123.0,
                "durationMs": 45.0,
                "remoteCall": [
                    "method": "METHOD",
                    "url": "URL",
                    "connectionType": "wifi",
                    "result": "res",
                    "responseCode": 321,
                    "requestSizeBytes": 11 as Instana.Types.Bytes,
                    "responseSizeBytes": 22 as Instana.Types.Bytes
                ]
            ]
        ])
    }
    
    func test_remoteCallDefaultValues() {
        let event = InstanaRemoteCallEvent(eventId: "b", duration: 0, method: "GET", url: "c", connectionType: nil, result: "r")
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": ComparisonType.nonEmptyString,
            "id": "b",
            "event": [
                "timestamp": ComparisonType.greaterThanZero,
                "durationMs": 0.0,
                "remoteCall": [
                    "method": "GET",
                    "url": "c",
                    "connectionType": ComparisonType.shouldBeNil,
                    "result": "r",
                    "responseCode": -1,
                    "requestSizeBytes": 0 as Instana.Types.Bytes,
                    "responseSizeBytes": 0 as Instana.Types.Bytes
                ]
            ]
        ])
    }
}
