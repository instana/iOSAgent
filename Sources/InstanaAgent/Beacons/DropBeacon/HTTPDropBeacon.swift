//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation

///
/// HTTP dropped beacon class
///
public class HTTPDropBeacon: DropBeacon {
    var url: String?
    var hsStatusCode: String?
    var view: String?
    var hmMethod: String?
    var headers: [String: String]?

    init(timestamp: Instana.Types.Milliseconds, url: String?, hsStatusCode: String?,
         view: String?, hmMethod: String?, headers: [String: String]?) {
        self.url = url
        self.hsStatusCode = hsStatusCode
        self.view = view
        self.hmMethod = hmMethod
        self.headers = headers
        super.init(timestamp: timestamp)
    }

    override func getKey() -> String {
        let url1 = url ?? ""
        let view1 = view ?? ""
        let hmMethod1 = hmMethod ?? ""
        let hsStatusCode1 = hsStatusCode ?? ""
        let headersStr = dictionaryToJsonString(headers) ?? ""
        return "\(url1)|\(view1)|\(hmMethod1)|\(hsStatusCode1)|\(headersStr)"
    }

    override func toString() -> String? {
        let url1 = url ?? ""
        let view1 = view ?? ""
        let hmMethod1 = hmMethod ?? ""
        let hsStatusCode1 = hsStatusCode ?? ""
        let zInfoExtra = ["url": url1, "hs": hsStatusCode1, "view": view1, "hm": hmMethod1,
                          "headers": headers ?? [:]] as [String: Any]
        return convertToString(type: "HTTP", subDict: zInfoExtra)
    }
}
