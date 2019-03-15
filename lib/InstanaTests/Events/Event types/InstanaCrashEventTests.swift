//  Created by Nikola Lajic on 3/14/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaCrashEventTests: XCTestCase {

    func test_crashEventValues_shouldBeSerializedToJSON() {
        let event = InstanaCrashEvent(sessionId: "a", timestamp: 123, report: "r", breadcrumbs: ["b","c"]) { _ in }
        compareDictionaries(original: event.toJSON(), expected: [
            "sessionId": "a",
            "id": ComparisonType.nonEmptyString,
            "crash": [
                "appVersion": InstanaSystemUtils.applicationVersion,
                "appBuildNumber": InstanaSystemUtils.applicationBuildNumber,
                "type": "iOS",
                "timestamp": 123.0,
                "report": "r",
                "breadcrumbs": ["b", "c"]
            ]
        ])
    }
}
