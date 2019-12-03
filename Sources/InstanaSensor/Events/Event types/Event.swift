//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Base class for events. 
@objc public class Event: NSObject {

    let timestamp: Instana.Types.Milliseconds
    let sessionId: String
    let eventId: String

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionId: String = Instana.sessionId) {
        self.sessionId = sessionId
        self.eventId = UUID().uuidString
        self.timestamp = timestamp
        super.init()
    }
    
    private override init() { fatalError() }
}

enum EventResult {
    case success
    case failure(error: Error)
}
