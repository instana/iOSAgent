//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

extension URL {
    static var random: URL {
        URL(string: "http://www.example.com/\((0...1000).randomElement() ?? 0)")!
    }
}

class MockHTTPURLResponse: HTTPURLResponse {
    var stubbedAllHeaderFields: [AnyHashable: Any] = ["":""]
    var stubbedStatusCode: Int = 200
    override var allHeaderFields: [AnyHashable : Any] { stubbedAllHeaderFields }
    override var statusCode: Int { stubbedStatusCode }
    override func value(forHTTPHeaderField field: String) -> String? {
        (allHeaderFields as NSDictionary)[field] as? String
    }
}

class MockURLSessionTask: URLSessionTask {
    var stubbedResponse: URLResponse?
    override var response: URLResponse? { stubbedResponse }
}

class MockURLSessionTaskMetrics: URLSessionTaskMetrics {
    var stubbedTransactionMetrics = [URLSessionTaskTransactionMetrics]()
    override var transactionMetrics: [URLSessionTaskTransactionMetrics] { stubbedTransactionMetrics }
    static var random: MockURLSessionTaskMetrics {
        let sessionTaskMetrics = MockURLSessionTaskMetrics()
        if #available(iOS 13.0, *) {
            sessionTaskMetrics.stubbedTransactionMetrics = [MockURLSessionTaskTransactionMetrics.random]
        }
        return sessionTaskMetrics
    }
}

class MockURLSessionTaskTransactionMetrics: URLSessionTaskTransactionMetrics {
    var stubbedCountOfResponseHeaderBytesReceived: Int64 = 0
    var stubbedCountOfResponseBodyBytesReceived: Int64 = 0
    var stubbedCountOfResponseBodyBytesAfterDecoding: Int64 = 0

    static var random: MockURLSessionTaskTransactionMetrics {
        let metrics = MockURLSessionTaskTransactionMetrics(stubbedCountOfResponseHeaderBytesReceived: (1...100).randomElement() ?? 1)
        metrics.stubbedCountOfResponseBodyBytesReceived = (1...100).randomElement() ?? 1
        metrics.stubbedCountOfResponseBodyBytesAfterDecoding = (1...100).randomElement() ?? 1
        return metrics
    }
    override var countOfResponseHeaderBytesReceived: Int64 { stubbedCountOfResponseHeaderBytesReceived }
    override var countOfResponseBodyBytesReceived: Int64 { stubbedCountOfResponseBodyBytesReceived }
    override var countOfResponseBodyBytesAfterDecoding: Int64 { stubbedCountOfResponseBodyBytesAfterDecoding }

    init(stubbedCountOfResponseHeaderBytesReceived: Int64) {
        self.stubbedCountOfResponseHeaderBytesReceived = stubbedCountOfResponseHeaderBytesReceived
        super.init()
    }

    init(stubbedCountOfResponseBodyBytesReceived: Int64) {
        self.stubbedCountOfResponseBodyBytesReceived = stubbedCountOfResponseBodyBytesReceived
        super.init()
    }

    init(stubbedCountOfResponseBodyBytesAfterDecoding: Int64) {
        self.stubbedCountOfResponseBodyBytesAfterDecoding = stubbedCountOfResponseBodyBytesAfterDecoding
        super.init()
    }
}

extension HTTPMarker.Size {
    static var random: HTTPMarker.Size { HTTPMarker.Size(header: (0...1000).randomElement() ?? 1,
                                                         body: (0...1000).randomElement() ?? 1,
                                                         bodyAfterDecoding: (0...1000).randomElement() ?? 1) }
}
