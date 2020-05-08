import Foundation

class SessionProfileBeacon: Beacon {
    enum State {
        case start
        case end
    }

    let state: State

    init(state: State, timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.state = state
        super.init(timestamp: timestamp)
    }

    private override init(timestamp: Instana.Types.Milliseconds, viewName: String?) {
        fatalError("Wrong initializer")
    }
}
