//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaCrashEvent: InstanaInternalEvent, InstanaEventResultNotifiable {
    let sessionId: String
    let eventId: String = UUID().uuidString
    let timestamp: Instana.Types.UTCTimestamp
    let completion: InstanaEventResultNotifiable.CompletionBlock
    let report: String
    
    init(sessionId: String, timestamp: Instana.Types.UTCTimestamp, report: String, completion: @escaping InstanaEventResultNotifiable.CompletionBlock) {
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.report = report
        self.completion = completion
    }
    
    func toJSON() -> [String : Any] {
        return [
            "sessionId": sessionId,
            "id": eventId,
            // TODO: add app data (version, build, etc.)
            "crash": [
                "type": "iOS",
                "timestamp": timestamp,
                "report": report
            ]
        ]
    }
}
