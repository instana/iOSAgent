//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class SessionProfileEvent: Event {

    enum State {
        case start
        case end
    }

    let state: State

    init(state: State,
         timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionId: String) {
        self.state = state
        super.init(timestamp: timestamp, sessionId: sessionId)
    }
    
    private override init(timestamp: Instana.Types.Milliseconds, sessionId: String) {
        fatalError("Wrong initializer")
    }
}
