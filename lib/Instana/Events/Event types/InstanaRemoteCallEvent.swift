//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaRemoteCallEvent: InstanaEvent {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: String
    let responseCode: Int
    let result: String
    
    init(eventId: String, timestamp: Instana.Types.UTCTimestamp = Date().timeIntervalSince1970, duration: Instana.Types.Milliseconds, method: String, url: String, responseCode: Int = -1, result: String) {
        self.duration = duration
        self.method = method
        self.url = url
        self.responseCode = responseCode
        self.result = result
        super.init(eventId: eventId, timestamp: timestamp)
    }
    
    override func toJSON() -> [String : Any] {
        var json = super.toJSON()
        json["event"] = [
            "timestamp": timestamp,
            "durationMs": duration,
            "remoteCall": [
                "method": method,
                "url": url,
                "result": result,
                "responseCode": responseCode
            ]
        ]
        return json
    }
}
