//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class InstanaSession {
    /// The current Instana configuration
    @Atomic var configuration: InstanaConfiguration

    /// Instana global property handler that will attach the custom properties to each monitored event. (beacon)
    /// Those values can be changed any time by the Instana agent consumer (i.e. iOS app).
    /// This class is thread-safe
    @Atomic var propertyHandler: InstanaPropertyHandler

    /// The Session ID created on each app launch
    let id: UUID

    /// A debugging console logger using levels
    let logger = InstanaLogger()

    /// Collecting and reporting can be disabled or enabled at any time
    @Atomic var collectionEnabled: Bool

    init(configuration: InstanaConfiguration, propertyHandler: InstanaPropertyHandler, sessionID: UUID = UUID(), collectionEnabled: Bool) {
        self.configuration = configuration
        self.propertyHandler = propertyHandler
        self.collectionEnabled = collectionEnabled
        id = sessionID
    }
}
