//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable @_spi(Internal) import InstanaAgent

class InstanaLoggerTests: InstanaTestCase {

    func test_enumNone() {
        Instana.current?.session.logger.add("mock .none logger message", level: .none)
    }
}
