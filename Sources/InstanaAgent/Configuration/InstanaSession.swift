//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class InstanaSession {
    let lock = NSLock()
    /// The current Instana configuration
    let configuration: InstanaConfiguration

    /// Instana global property handler that will attach the custom properties to each monitored event. (beacon)
    /// Those values can be changed any time by the Instana agent consumer (i.e. iOS app).
    /// This class is thread-safe

    let propertyHandler: InstanaPropertyHandler

    /// The Session ID created on each app launch
    let id: UUID

    /// A debugging console logger using levels
    let logger = InstanaLogger()

    private var unsafe_collectionEnabled: Bool
    var collectionEnabled: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return unsafe_collectionEnabled
        }
        set {
            lock.lock()
            unsafe_collectionEnabled = newValue
            lock.unlock()
        }
    }

    init(configuration: InstanaConfiguration, propertyHandler: InstanaPropertyHandler, sessionID: UUID = UUID(), collectionEnabled: Bool) {
        self.configuration = configuration
        self.propertyHandler = propertyHandler
        unsafe_collectionEnabled = collectionEnabled
        id = sessionID
    }
}
