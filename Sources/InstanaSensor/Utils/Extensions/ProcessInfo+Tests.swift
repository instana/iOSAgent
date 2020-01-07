import Foundation

extension ProcessInfo {
    var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var isRunningUITests: Bool {
        return ProcessInfo.processInfo.environment["UITestsActive"] == "true"
    }
}
