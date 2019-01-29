//  Created by Nikola Lajic on 1/29/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

extension Collection where Element: InstanaEvent {
    func toBatchRequest() throws -> URLRequest {
        guard var url = URL(string: Instana.reportingUrl) else {
            throw InstanaError(code: .invalidRequest, description: "Invalid reporting url. No data will be sent.")
        }
        guard let key = Instana.key else {
            throw InstanaError(code: .notAuthenticated, description: "Missing application key. No data will be sent.")
        }
        url.appendPathComponent("v1/api/\(key)/batch")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEvents = compactMap { $0.toJSON() }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonEvents) else {
            throw InstanaError(code: .invalidRequest, description: "Could not serialize events data.")
        }
        
        if let gzippedData = try? (jsonData as NSData).gzipped(withCompressionLevel: -1) { // -1 default compression level
            urlRequest.httpBody = gzippedData
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.setValue("\(gzippedData.count)", forHTTPHeaderField: "Content-Length")
        }
        else {
            urlRequest.httpBody = jsonData
        }
        
        return urlRequest
    }
    
    func invokeCallbackIfNeeded(with result: InstanaEventResult) {
        forEach { event in
            if let notifiableEvent = event as? InstanaEventResultNotifiable {
                notifiableEvent.completion(result);
            }
        }
    }
}
