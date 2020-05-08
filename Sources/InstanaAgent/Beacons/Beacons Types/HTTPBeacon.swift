import Foundation

class HTTPBeacon: Beacon {
    let duration: Instana.Types.Milliseconds
    let method: String
    let url: URL
    let path: String?
    let responseCode: Int
    let responseSize: HTTPMarker.Size?
    var backendTracingID: String?
    var error: HTTPError?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         duration: Instana.Types.Milliseconds = 0,
         method: String,
         url: URL,
         responseCode: Int,
         responseSize: HTTPMarker.Size? = nil,
         error: Error? = nil,
         backendTracingID: String? = nil,
         viewName: String? = nil) {
        let path = !url.path.isEmpty ? url.path : nil
        self.duration = duration
        self.method = method
        self.url = url
        self.path = path
        self.responseCode = responseCode
        self.responseSize = responseSize
        self.error = HTTPError(error: error as NSError?, statusCode: responseCode)
        self.backendTracingID = backendTracingID
        super.init(timestamp: timestamp, viewName: viewName)
    }
}
