import Foundation

class InstanaLogger {
    enum Level: Int, RawRepresentable {
        case debug, warning, error, none
        fileprivate var logTag: String {
            switch self {
            case .debug: return "[Debug]"
            case .warning: return "[Warning]"
            case .error: return "[Error]"
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
            print("[Instana]\(level.logTag) \(entry)")
        #endif
    }
}
