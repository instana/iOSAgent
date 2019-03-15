//  Created by Nikola Lajic on 1/29/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

extension Collection where Element: InstanaEvent {
    
    func toBatchRequest(key: String? = Instana.key, reportingUrl: String = Instana.reportingUrl, compress: (Data) throws -> Data = compress(data:)) throws -> URLRequest {
        guard var url = URL(string: reportingUrl) else {
            throw InstanaError(code: .invalidRequest, description: "Invalid reporting url. No data will be sent.")
        }
        guard let key = key else {
            throw InstanaError(code: .notAuthenticated, description: "Missing application key. No data will be sent.")
        }
        url.appendPathComponent("v1/api/\(key)/batch")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try serializeToJSONData()
        
        if let gzippedData = try? compress(jsonData) {
            urlRequest.httpBody = gzippedData
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.setValue("\(gzippedData.count)", forHTTPHeaderField: "Content-Length")
        }
        else {
            urlRequest.httpBody = jsonData
        }
        
        return urlRequest
    }
    
    private func serializeToJSONData() throws -> Data {
        let jsonEvents = compactMap { $0.toJSON() }
        // we have to check the vailidty of `jsonEvents` since `data(withJSONObject:)` is catchable only for "internal errors"
        guard JSONSerialization.isValidJSONObject(jsonEvents), let jsonData = try? JSONSerialization.data(withJSONObject: jsonEvents) else {
            throw InstanaError(code: .invalidRequest, description: "Could not serialize events data.")
        }
        return jsonData
    }
    
    private static func compress(data: Data) throws -> Data {
        // -1 default compression level
        return try (data as NSData).gzipped(withCompressionLevel: -1)
    }
}

extension Collection where Element: InstanaEvent {
    func invokeCallbackIfNeeded(with result: InstanaEventResult) {
        forEach { event in
            if let notifiableEvent = event as? InstanaEventResultNotifiable {
                notifiableEvent.completion(result);
            }
        }
    }
}
