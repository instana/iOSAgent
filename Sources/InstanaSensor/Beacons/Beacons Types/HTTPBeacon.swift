//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class HTTPBeacon: Beacon {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: URL
    let path: String?
    let responseCode: Int
    let result: String
    let requestSize: Instana.Types.Bytes
    let responseSize: Instana.Types.Bytes
    
    init(timestamp: Instana.Types.Milliseconds,
         duration: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         method: String,
         url: URL,
         responseCode: Int = -1,
         requestSize: Instana.Types.Bytes = 0,
         responseSize: Instana.Types.Bytes = 0,
         result: String) {
        self.duration = duration
        self.method = method
        self.url = url
        self.path = !url.path.isEmpty ? url.path : nil
        self.responseCode = responseCode
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.result = result
        super.init(timestamp: timestamp)
    }
}
