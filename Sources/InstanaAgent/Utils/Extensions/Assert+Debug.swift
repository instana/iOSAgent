import Foundation

public func debugAssertFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if !ProcessInfo.processInfo.isRunningTests {
        assertionFailure(message(), file: file, line: line)
    }
}

public func debugAssert(_ condition: @autoclosure () -> Bool,
                        _ message: @autoclosure () -> String = String(),
                        file: StaticString = #file,
                        line: UInt = #line) {
    if !ProcessInfo.processInfo.isRunningTests {
        assert(condition(), message(), file: file, line: line)
    }
}
