//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Base class for events. 
class Event: Identifiable {

    let timestamp: Instana.Types.Milliseconds
    let sessionId: String
    var id: String

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionId: String = Instana.current.sessionId) {
        self.sessionId = sessionId
        self.id = UUID().uuidString
        self.timestamp = timestamp
    }
}

enum EventResult {
    case success
    case failure(Error)

    var error: Error? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}
