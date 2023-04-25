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
        XCTAssertEqual(anotherDay.description, today.description)
    }
}
