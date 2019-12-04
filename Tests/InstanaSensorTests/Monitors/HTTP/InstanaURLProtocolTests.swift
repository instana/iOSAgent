//  Created by Nikola Lajic on 3/20/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaURLProtocolTests: XCTestCase {
    let makeRequest: (String) -> URLRequest = { URLRequest(url: URL(string: $0)!) }

    func test_urlProtocol_shouldOnlyInitForSupportedSchemes() {
        XCTAssertTrue(InstanaURLProtocol.canInit(with: makeRequest("https://www.a.b")))
        XCTAssertTrue(InstanaURLProtocol.canInit(with: makeRequest("http://www.a.c")))
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("www.a.c")))
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("ws://a")))
    }
    
    func test_urlProtocol_shouldNotModifyCanonicalRequest() {
        let request = makeRequest("http://www.test.com")
        let cannonialRequest = InstanaURLProtocol.canonicalRequest(for: request)
        XCTAssertEqual(request, cannonialRequest)
    }
    
    func test_urlProtocol_shouldExtractInternalTaskSessionConfiguration() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 123
        let task = URLSession(configuration: configuration).dataTask(with: makeRequest("http://www.a.c"))
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)
        XCTAssertEqual(urlProtocol.sessionConfiguration.timeoutIntervalForRequest, 123)
    }
    
    func test_urlProtocol_shouldRemoveSelfFromCopiedInternalTaskSessionConfiguration() {
        let configuration = URLSessionConfiguration.default
        HTTPMonitor(InstanaConfiguration.default(key: "KEY"), reporter: MockReporter()).track(configuration)
        let task = URLSession(configuration: configuration).dataTask(with: makeRequest("http://www.a.c"))
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)
        XCTAssertFalse(urlProtocol.sessionConfiguration.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? true)
    }
}
