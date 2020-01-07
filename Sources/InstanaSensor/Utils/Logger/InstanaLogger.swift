import Foundation

class InstanaLogger {

    enum Level: Int {
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

    var level: Level = .debug

    func add(_ entry: String, level: Level = .debug) {
        guard level.rawValue >= self.level.rawValue else { return }
#if DEBUG
        print("[Instana]\(level.logTag) \(entry)")
#endif
    }
}
