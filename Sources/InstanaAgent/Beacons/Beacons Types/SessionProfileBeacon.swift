import Foundation

class SessionProfileBeacon: Beacon {
    enum State {
        case start
        case end
    }

    let state: State

    init(state: State,
         timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionID: UUID) {
        self.state = state
        super.init(timestamp: timestamp, sessionID: sessionID)
    }

    private override init(timestamp: Instana.Types.Milliseconds, sessionID: UUID, viewName: String?) {
        fatalError("Wrong initializer")
    }
}
