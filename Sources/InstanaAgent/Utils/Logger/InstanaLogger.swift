//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import os

class InstanaLogger {
    enum Level: Int, RawRepresentable {
        case debug, warning, error, none
        fileprivate var logTag: String {
            switch self {
            case .debug: return "Debug"
            case .warning: return "Warning"
            case .error: return "Error"
            case .none: return ""
            }
        }
    }

    let level: Level
    init() {
        let envLogLevel = Int(ProcessInfo.processInfo.environment["INSTANA_DEBUG_LOGLEVEL"] ?? "")
        level = Level(rawValue: envLogLevel ?? Level.none.rawValue) ?? .none
    }

    func add(_ entry: String, level: Level = .debug) {
        guard level.rawValue >= self.level.rawValue else { return }
        #if DEBUG
            let message = "[Instana]: \(entry)"
            if #available(iOS 14.0, *) {
                let logger = os.Logger(subsystem: "com.instana.ios.agent.logging", category: level.logTag)
                switch level {
                case .debug:
                    logger.debug("\(message)")
                case .warning:
                    logger.warning("\(message)")
                case .error:
                    logger.error("\(message)")
                case .none:
                    break
                }
            } else {
                print(message)
            }
        #endif
    }
}
