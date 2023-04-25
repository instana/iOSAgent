//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class ProcessInfoPlusExtrasTests: InstanaTestCase {

    func test_ignoreZIPReporting() {
        // default
        var ignore = ProcessInfo.ignoreZIPReporting
        XCTAssertFalse(ignore)

        // When
        UserDefaults.standard.setValue("true", forKey: ignoreZipReportingKey)
        ignore = ProcessInfo.ignoreZIPReporting

        // Then
        XCTAssertTrue(ignore)

        // restore
        UserDefaults.standard.removeObject(forKey: ignoreZipReportingKey)
    }
}
