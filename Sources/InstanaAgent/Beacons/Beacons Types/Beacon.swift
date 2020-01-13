import Foundation

/// Base class for Beacon.
class Beacon: Identifiable {
    let timestamp: Instana.Types.Milliseconds
    let sessionID: UUID
    let viewName: String?
    var id: UUID

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionID: UUID = Instana.current?.environment.sessionID ?? UUID(),
         viewName: String? = nil) {
        id = UUID()
        self.sessionID = sessionID
        self.timestamp = timestamp

        if let stateActive = InstanaSystemUtils.isAppActive {
            let name = viewName ?? Instana.current?.environment.propertyHandler.properties.view
            self.viewName = stateActive ? name : "Background"
        } else {
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
