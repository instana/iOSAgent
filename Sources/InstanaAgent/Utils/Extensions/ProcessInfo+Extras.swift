//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

public extension ProcessInfo {
    static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var ignoreZIPReporting: Bool {
        var ignore = ""
        if let ignoreViaLaunchArguments = UserDefaults.standard.string(forKey: ignoreZipReportingKey) {
            ignore = ignoreViaLaunchArguments
        } else {
            ignore = ProcessInfo.processInfo.environment[ignoreZipReportingKey] ?? ""
        }
        return ignore == "true"
    }

    static var isRunningDebugSessionSimulator: Bool {
        if isRunningTests {
            return false
        }
        if let uuid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"], uuid.count > 0 {
            return true
        }
        return false
    }
}
