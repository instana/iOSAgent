import Foundation

/// Base class for Beacon.
class Beacon: Identifiable {
    let timestamp: Instana.Types.Milliseconds
    let sessionID: UUID
    let viewName: String?
    var id: UUID

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionID: UUID = Instana.current?.session.id ?? UUID(),
         viewName: String? = nil) {
        id = UUID()
        self.sessionID = sessionID
        self.timestamp = timestamp
        switch InstanaApplicationStateHandler.shared.state {
        case .active:
            self.viewName = viewName ?? Instana.current?.session.propertyHandler.properties.view
        case .background:
            self.viewName = "Background"
        case .inactive:
            self.viewName = "Inactive"
        case .undefined:
            self.viewName = nil
        }
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
