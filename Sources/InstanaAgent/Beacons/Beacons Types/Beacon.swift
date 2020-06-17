import Foundation

/// Base class for Beacon.
class Beacon {
    let id = UUID()
    var timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970
    let viewName: String?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         viewName: String? = nil) {
        self.timestamp = timestamp
        self.viewName = viewName
    }
}

enum BeaconResult {
    case success
    case failure(Error)

    var error: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }
}
