import Foundation

class HTTPBeacon: Beacon {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: URL
    let path: String?
    let responseCode: Int
    let result: String
    let responseSize: Instana.Types.HTTPSize?
    var backendTracingID: String?

    init(timestamp: Instana.Types.Milliseconds,
         duration: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         method: String,
         url: URL,
         responseCode: Int,
         responseSize: Instana.Types.HTTPSize? = nil,
         result: String,
         backendTracingID: String? = nil) {
        self.duration = duration
        self.method = method
        self.url = url
        path = !url.path.isEmpty ? url.path : nil
        self.responseCode = responseCode
        self.responseSize = responseSize
        self.result = result
        self.backendTracingID = backendTracingID
        super.init(timestamp: timestamp)
    }
}
