//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class SessionProfileBeacon: Beacon {

    enum State {
        case start
        case end
    }

    let state: State

    init(state: State,
         timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         sessionID: UUID) {
        self.state = state
        super.init(timestamp: timestamp, sessionID: sessionID)
    }
    
    private override init(timestamp: Instana.Types.Milliseconds, sessionID: UUID) {
        fatalError("Wrong initializer")
    }
}
