//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class HTTPEvent: Event {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: String
    let path: String
    let connectionType: InstanaNetworkMonitor.ConnectionType?
    let responseCode: Int
    let result: String
    let requestSize: Instana.Types.Bytes
    let responseSize: Instana.Types.Bytes
    
    init(eventId: String,
         timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         duration: Instana.Types.Milliseconds = Date().millisecondsSince1970,
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
        self.path = URL(string: url)?.path ?? ""
        self.connectionType = connectionType
        self.responseCode = responseCode
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.result = result
        super.init(eventId: eventId, timestamp: timestamp)
    }
}
