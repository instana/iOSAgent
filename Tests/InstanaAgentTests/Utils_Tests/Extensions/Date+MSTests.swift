//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class DatePlusMSTests: InstanaTestCase {
    func test_init() {
        // Given
        let today = Date()

        // When
        let since1970 = today.timeIntervalSince1970
        let millis: Int64 = Int64(since1970 * 1000)
        let anotherDay = Date(milliseconds: millis)

        // Then
        if #available(iOS 13.0, *) {
            XCTAssertLessThanOrEqual(abs(anotherDay.distance(to: today)), 1.0)
        } else {
            // Small chance exists that this test fails due to roundup accuracy loss
            XCTAssertEqual(anotherDay.description, today.description)
        }
    }
}
