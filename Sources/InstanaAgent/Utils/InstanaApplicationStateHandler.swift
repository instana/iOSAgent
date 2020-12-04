import Foundation
import UIKit

// We need an abstract state handler to make the Notifications (didBecomeActiveNotification, ...) easier to test
class InstanaApplicationStateHandler {
    enum State {
        case active
        case inactive
        case background
    }

    static let shared = InstanaApplicationStateHandler()

    @Atomic var state: State = .active {
        didSet { stateUpdateHandler.forEach { $0(state) } }
    }

    typealias StateUpdater = (State) -> Void
    private var stateUpdateHandler = [StateUpdater]()

    init() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            self.state = .active
        }
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostDidBecomeActive, object: nil, queue: nil) { _ in
            self.state = .active
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.state = .background
        }
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostDidEnterBackground, object: nil, queue: nil) { _ in
            self.state = .background
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { _ in
            self.state = .inactive
        }
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostWillResignActive, object: nil, queue: nil) { _ in
            self.state = .inactive
        }
    }

    func listen(_ handler: @escaping StateUpdater) {
        stateUpdateHandler.append(handler)
    }

    func removeAllListener() {
        stateUpdateHandler.removeAll()
    }
}
