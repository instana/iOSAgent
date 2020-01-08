import Foundation

class HTTPBeacon: Beacon {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: URL
    let path: String?
    let responseCode: Int
    let responseSize: Instana.Types.HTTPSize?
    var backendTracingID: String?
    var error: HTTPError?

    init(timestamp: Instana.Types.Milliseconds,
         duration: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         method: String,
         url: URL,
         responseCode: Int,
         responseSize: Instana.Types.HTTPSize? = nil,
         error: Error? = nil,
         backendTracingID: String? = nil) {
        let path = !url.path.isEmpty ? url.path : nil
        self.duration = duration
        self.method = method
        self.url = url
        self.path = path
        self.responseCode = responseCode
        self.responseSize = responseSize
        self.error = HTTPError(error: error as NSError?, statusCode: responseCode)
        self.backendTracingID = backendTracingID
        super.init(timestamp: timestamp)
    }
}
