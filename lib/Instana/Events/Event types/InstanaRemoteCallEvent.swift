//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaRemoteCallEvent: InstanaInternalEvent {
    
    let sessionId: String = Instana.sessionId
    let eventId: String = UUID().uuidString
    let timestamp: Instana.Types.UTCTimestamp
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: String
    let responseCode: Int?
    let result: String
    
    init(timestamp: Instana.Types.UTCTimestamp = Date().timeIntervalSince1970, duration: Instana.Types.Milliseconds, method: String, url: String, responseCode: Int?, result: String) {
        self.timestamp = timestamp
        self.duration = duration
        self.method = method
        self.url = url
        self.responseCode = responseCode
        self.result = result
    }
    
    func toJSON() -> [String : Any] {
        var remoteCall: [String: Any] = [
            "method": method,
            "url": url,
            "result": result
        ]
        if let responseCode = responseCode {
            remoteCall["responseCode"] = responseCode
        }
        return [
            "sessionId": sessionId,
            "id": eventId,
            "event": [
                "timestamp": timestamp,
                "durationMs": duration,
                "remoteCall": remoteCall
            ]
        ]
    }
}
