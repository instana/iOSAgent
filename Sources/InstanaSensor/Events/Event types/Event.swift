//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Base class for events. 
@objc public class Event: NSObject {
    let sessionId: String
    let eventId: String?
    let timestamp: Instana.Types.Milliseconds
    
    init(sessionId: String = Instana.sessionId,
         eventId: String? = UUID().uuidString,
         timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.sessionId = sessionId
        self.eventId = eventId
        self.timestamp = timestamp
        super.init()
    }
    
    private override init() { fatalError() }
}

enum EventResult {
    case success
    case failure(error: Error)
}

protocol EventResultNotifiable {
    typealias CompletionBlock = (_ result: EventResult) -> Void
    var completion: CompletionBlock { get }
}
