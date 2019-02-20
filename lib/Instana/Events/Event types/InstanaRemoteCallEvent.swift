//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaRemoteCallEvent: InstanaEvent {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: String
    let responseCode: Int
    let result: String
    let requestSize: Instana.Types.Bytes
    let responseSize: Instana.Types.Bytes
    
    init(eventId: String,
         timestamp: Instana.Types.UTCTimestamp = Date().timeIntervalSince1970,
         duration: Instana.Types.Milliseconds,
         method: String,
         url: String,
         responseCode: Int = -1,
         requestSize: Instana.Types.Bytes = 0,
         responseSize: Instana.Types.Bytes = 0,
         result: String) {
        self.duration = duration
        self.method = method
        self.url = url
        self.responseCode = responseCode
        self.requestSize = requestSize
        self.responseSize = responseSize
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
                "responseCode": responseCode,
                "requestSizeBytes:": requestSize,
                "responseSizeBytes": responseSize
            ]
        ]
        return json
    }
}
