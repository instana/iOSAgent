import Foundation
@testable import InstanaSensor

extension HTTPBeacon {

    static func createMock(timestamp: Int64 = Date().millisecondsSince1970,
                 method: String = "POST",
                 error: Error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil),
                 url: URL = URL(string: "https://www.example.com")!) -> HTTPBeacon {
           return HTTPBeacon(timestamp: timestamp,
                            method: method,
                            url: url,
                            responseCode: 200,
                            responseSize:  Instana.Types.HTTPSize(),
                            error: error,
                            backendTracingID: "BackendTracingID")
       }
}
