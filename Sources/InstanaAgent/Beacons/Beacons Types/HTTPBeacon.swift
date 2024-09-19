//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class HTTPBeacon: Beacon {
    static let maxLengthURL: Int = 4096

    let duration: Instana.Types.Milliseconds
    let method: String
    let url: URL
    let path: String?
    let header: [String: String]?
    let responseCode: Int
    let responseSize: HTTPMarker.Size?
    var backendTracingID: String?
    var error: HTTPError?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         duration: Instana.Types.Milliseconds = 0,
         method: String,
         url: URL,
         header: [String: String]? = nil,
         responseCode: Int,
         responseSize: HTTPMarker.Size? = nil,
         error: Error? = nil,
         backendTracingID: String? = nil,
         viewName: String? = nil) {
        let path = !url.path.isEmpty ? url.path : nil
        self.duration = duration
        self.method = method
        let urlString = url.absoluteString.cleanEscapeAndTruncate(at: Self.maxLengthURL, trailing: "")
        self.url = URL(string: urlString) ?? url
        self.header = header
        self.path = path
        self.responseCode = responseCode
        self.responseSize = responseSize
        self.error = HTTPError(error: error as NSError?, statusCode: responseCode)
        self.backendTracingID = backendTracingID
        super.init(timestamp: timestamp, viewName: viewName)
    }

    override func extractDropBeaconValues() -> HTTPDropBeacon {
        return HTTPDropBeacon(timestamp: timestamp, url: url.absoluteString,
                              hsStatusCode: String(responseCode),
                              view: viewName, hmMethod: method, headers: header)
    }
}
