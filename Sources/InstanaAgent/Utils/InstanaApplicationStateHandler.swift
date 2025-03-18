//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(macOS)
    import AppKit
    typealias Application = NSApplication
#elseif os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
    typealias Application = UIApplication
#endif

// We need an abstract state handler to make the Notifications (didBecomeActiveNotification, ...) easier to test
class InstanaApplicationStateHandler {
    enum State {
        case active
        case inactive
        case background
    }

    static let shared = InstanaApplicationStateHandler()

    @Atomic var state: State = .active {
        didSet { stateUpdateHandler.forEach { $0(state, oldValue) } }
    }

    typealias StateUpdater = (State, State) -> Void
    private var stateUpdateHandler = AtomicArray<StateUpdater>()

    init() {
        _ = NotificationCenter.default.addObserver(forName: Application.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            self.state = .inactive
        }
        _ = NotificationCenter.default.addObserver(forName: Application.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            self.state = .active
        }
        _ = NotificationCenter.default.addObserver(forName: Application.willResignActiveNotification, object: nil, queue: nil) { _ in
            self.state = .inactive
        }

        #if os(tvOS) || os(watchOS) || os(iOS)
            _ = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
                self.state = .background
            }
            _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostWillResignActive, object: nil, queue: nil) { _ in
                self.state = .inactive
            }
            _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostDidBecomeActive, object: nil, queue: nil) { _ in
                self.state = .active
            }
            _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSExtensionHostDidEnterBackground, object: nil, queue: nil) { _ in
                self.state = .background
            }
        #elseif os(macOS)
            _ = NotificationCenter.default.addObserver(forName: NSApplication.didHideNotification, object: nil, queue: nil) { _ in
                self.state = .background
            }
            _ = NotificationCenter.default.addObserver(forName: NSApplication.didUnhideNotification, object: nil, queue: nil) { _ in
                self.state = .active
            }
        #endif
    }

    func listen(_ handler: @escaping StateUpdater) {
        stateUpdateHandler.append(handler)
    }

    func removeAllListener() {
        stateUpdateHandler.removeAll()
    }

    func getAppStateForBeacon() -> String? {
        switch state {
        case .active:
            return "f"
        case .background:
            return "b"
        default:
            return "u"
        }
    }
}
