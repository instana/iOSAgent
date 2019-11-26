//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class HTTPEvent: Event {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: String
    let connectionType: InstanaNetworkMonitor.ConnectionType?
    let responseCode: Int
    let result: String
    let requestSize: Instana.Types.Bytes
    let responseSize: Instana.Types.Bytes
    
    init(eventId: String,
         timestamp: Instana.Types.UTCTimestamp = Date().timeIntervalSince1970,
         duration: Instana.Types.Milliseconds,
         method: String,
         url: String,
         connectionType: InstanaNetworkMonitor.ConnectionType?,
         responseCode: Int = -1,
         requestSize: Instana.Types.Bytes = 0,
         responseSize: Instana.Types.Bytes = 0,
         result: String) {
        self.duration = duration
        self.method = method
        self.url = url
        self.connectionType = connectionType
        self.responseCode = responseCode
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.result = result
        super.init(eventId: eventId, timestamp: timestamp)
    }
    
    override func toJSON() -> [String : Any] {
        var json = super.toJSON()
        var remoteCall: [String: Any] = [
            "method": method,
            "url": url,
            "result": result,
            "responseCode": responseCode,
            "requestSizeBytes": requestSize,
            "responseSizeBytes": responseSize
        ]
        if let connectionType = connectionType {
            remoteCall["connectionType"] = String(describing: connectionType)
        }
        remoteCall.set(ifNotNil: InstanaSystemUtils.carrierName, forKey: "carrier")
        remoteCall.set(ifNotNil: InstanaSystemUtils.cellularConnectionType, forKey: "cellularConnectionType")
        json["event"] = [
            "timestamp": timestamp,
            "durationMs": duration,
            "remoteCall": remoteCall
        ]
        return json
    }
}
