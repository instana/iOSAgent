//
//  File.swift
//  
//
//  Created by Christian Menschel on 29.11.19.
//

import Foundation

extension ProcessInfo {
    var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var isRunningUITests: Bool  {
        return ProcessInfo.processInfo.environment["UITestsActive"] == "true"
    }
}
