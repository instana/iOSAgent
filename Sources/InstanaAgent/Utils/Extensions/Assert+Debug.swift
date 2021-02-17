//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

public func debugAssertFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if !ProcessInfo.isRunningTests {
        assertionFailure(message(), file: file, line: line)
    }
}

public func debugAssert(_ condition: @autoclosure () -> Bool,
                        _ message: @autoclosure () -> String = String(),
                        file: StaticString = #file,
                        line: UInt = #line) {
    if !ProcessInfo.isRunningTests {
        assert(condition(), message(), file: file, line: line)
    }
}
