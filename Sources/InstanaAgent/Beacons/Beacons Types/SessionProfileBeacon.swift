import Foundation

class SessionProfileBeacon: Beacon {
    enum State {
        case start
        case end
    }

    let state: State

    required init(state: State, timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.state = state
        super.init(timestamp: timestamp)
    }

    private convenience override init(timestamp: Instana.Types.Milliseconds, viewName: String?) {
        self.init(state: .start)
        Instana.current?.session.logger.add("Wrong init - Please use init(state: State, timestamp: Instana.Types.Milliseconds) instead", level: .error)
    }
}
