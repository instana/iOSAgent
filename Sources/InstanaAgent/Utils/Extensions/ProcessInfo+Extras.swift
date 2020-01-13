import Foundation

extension ProcessInfo {
    static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var isRunningUITests: Bool {
        return ProcessInfo.processInfo.environment["UITestsActive"] == "true"
    }

    static var isRunningDebugSessionSimulator: Bool {
        if isRunningTests || isRunningUITests {
            return false
        }
        if let uuid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"], uuid.count > 0 {
            return true
        }
        return false
    }
}
