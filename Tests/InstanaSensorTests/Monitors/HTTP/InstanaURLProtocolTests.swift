//  Created by Nikola Lajic on 3/20/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaURLProtocolTests: XCTestCase {
    let makeRequest: (String) -> URLRequest = { URLRequest(url: URL(string: $0)!) }

    func test_urlProtocol_disabled() {
        // Given
        InstanaURLProtocol.mode = .disabled

        // Then
        XCTAssertTrue(InstanaURLProtocol.mode == .disabled)
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("https://www.a.b")))
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("http://www.a.c")))
    }

    func test_urlProtocol_shouldOnlyInitForSupportedSchemes() {
        // Given
        InstanaURLProtocol.mode = .enabled

        // Then
        XCTAssertTrue(InstanaURLProtocol.canInit(with: makeRequest("https://www.a.b")))
        XCTAssertTrue(InstanaURLProtocol.canInit(with: makeRequest("http://www.a.c")))
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("www.a.c")))
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("ws://a")))
    }
    
    func test_urlProtocol_shouldNotModifyCanonicalRequest() {
        // Given
        let request = makeRequest("http://www.test.com")

        // When
        let cannonialRequest = InstanaURLProtocol.canonicalRequest(for: request)

        // Then
        XCTAssertEqual(request, cannonialRequest)
    }
    
    func test_urlProtocol_shouldExtractInternalTaskSessionConfiguration() {
        // Given
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 123

        // When
        let task = URLSession(configuration: configuration).dataTask(with: makeRequest("http://www.a.c"))
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)

        // Then
        XCTAssertEqual(urlProtocol.sessionConfiguration.timeoutIntervalForRequest, 123)
    }
    
    func test_urlProtocol_shouldRemoveSelfFromCopiedInternalTaskSessionConfiguration() {
        // Given
        let configuration = URLSessionConfiguration.default

        // When
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
        let task = URLSession(configuration: configuration).dataTask(with: makeRequest("http://www.a.c"))
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)

        // When
        let protocolClasses = urlProtocol.sessionConfiguration.protocolClasses ?? []
        XCTAssertFalse(protocolClasses.contains { $0 == InstanaURLProtocol.self })
    }

    func test_swizzle_and_install_custom_urlSession_urlprotocol() {
        // Given
        InstanaURLProtocol.install() // Start the swizzle

        // When
        let session = URLSession(configuration: URLSessionConfiguration.default) // The actual swizzling is done here
        let sessionURLProtocols = session.configuration.protocolClasses ?? []

        // Then
        let allURLProtocolClasses = URLSession.allSessionConfigs.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})
        AssertTrue(sessionURLProtocols.contains {$0 == InstanaURLProtocol.self})
    }

    func test_store_URLSessionConfiguration() {
        // Given
        let config = URLSessionConfiguration.default

        // When
        URLSession.store(config: config)

        // Then
        AssertTrue(URLSession.allSessionConfigs.contains {$0 == config})
    }

    // Done without the Swizzle
    func test_store_and_install_urlProtocol() {
        // Given
        let config = URLSessionConfiguration.default

        // When
        InstanaURLProtocol.install()
        config.registerInstanaURLProtocol()

        // Then
        let allURLProtocolClasses = URLSession.allSessionConfigs.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains(where: {$0 == InstanaURLProtocol.self}))
        AssertTrue(URLSession.allSessionConfigs.contains {$0 == config})
    }

    func test_remove_urlprotocols() {
        // Given
        let config = URLSessionConfiguration.default
        InstanaURLProtocol.install()
        config.registerInstanaURLProtocol()

        // When
        URLSession.removeInstanaURLProtocol()

        // Then
        let allURLProtocolClasses = URLSession.allSessionConfigs.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(URLSession.allSessionConfigs.contains {$0 == config})
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self} == false)
    }

    // Integration Tests
    func test_finish_success() {
        // Given
        let delegate = Delegate()
        let backendTracingID = "981d9553578fc280"
        let url = URL.random
        let task = MockURLSessionTask()
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let metrics = MockURLSessionTaskMetrics.random
        let urlProtocol = InstanaURLProtocol()
        let marker = HTTPMarker(url: url, method: "GET", delegate: delegate)
        urlProtocol.marker = marker

        // When
        urlProtocol.urlSession(URLSession.shared, task: task, didFinishCollecting: metrics)
        urlProtocol.urlSession(URLSession.shared, task: task, didCompleteWithError: nil)

        // Then
        AssertEqualAndNotNil(urlProtocol.marker?.backendTracingID, backendTracingID)
        AssertEqualAndNotNil(urlProtocol.marker, marker)
        AssertTrue(delegate.calledFinalized)
        if case let .finished(responseCode) = urlProtocol.marker?.state {
            AssertTrue(responseCode == 200)
        } else {
            XCTFail("Wrong state for marker")
        }

        if #available(iOS 13.0, *) {
            let metric = metrics.transactionMetrics.first
            AssertEqualAndNotZero(urlProtocol.marker?.responseSize?.headerBytes ?? 0, metric?.countOfResponseHeaderBytesReceived ?? 0)
            AssertEqualAndNotZero(urlProtocol.marker?.responseSize?.bodyBytes ?? 0, metric?.countOfResponseBodyBytesReceived ?? 0)
            AssertEqualAndNotZero(urlProtocol.marker?.responseSize?.bodyBytesAfterDecoding ?? 0, metric?.countOfResponseBodyBytesAfterDecoding ?? 0)
        } else {
            AssertTrue(urlProtocol.marker?.responseSize?.headerBytes ?? 0 > 0)
            AssertEqualAndNotNil(urlProtocol.marker?.responseSize?.bodyBytes, response.expectedContentLength)
            AssertTrue(urlProtocol.marker?.responseSize?.bodyBytesAfterDecoding == nil)
        }
    }

    func test_finish_success_with_http_forward_301() {
        // Given
        Instana.setup(key: "KEY")
        let delegate = Delegate()
        let backendTracingID = "981d9553578fc280"
        let url = URL.random
        let task = MockURLSessionTask()
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedStatusCode = 301
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let urlProtocol = InstanaURLProtocol()
        let marker = HTTPMarker(url: url, method: "GET", delegate: delegate)
        urlProtocol.marker = marker
        let newRequest = URLRequest(url: URL.random)
        var expectedCompletionRequest: URLRequest?

        // When perfom the HTTP Forward
        urlProtocol.urlSession(URLSession.shared, task: task, willPerformHTTPRedirection: response, newRequest: newRequest) { comingRequest in
            expectedCompletionRequest = comingRequest
        }

        // Then
        AssertEqualAndNotNil(marker.backendTracingID, backendTracingID)
        AssertEqualAndNotNil(expectedCompletionRequest, newRequest)
        AssertTrue(delegate.calledFinalized)
        if case let .finished(responseCode) = marker.state {
            AssertTrue(responseCode == 301)
        } else {
            XCTFail("Wrong state for marker")
        }

        AssertTrue(marker.responseSize?.headerBytes ?? 0 > 0)
        AssertEqualAndNotNil(marker.responseSize?.bodyBytes, response.expectedContentLength)
        AssertTrue(marker.responseSize?.bodyBytesAfterDecoding == nil)

        // We expect a new marker created by the URLProtocol for the HTTP Forward
        AssertTrue(urlProtocol.marker?.backendTracingID == nil)
        XCTAssertNotNil(urlProtocol.marker)
        AssertTrue(urlProtocol.marker != marker)
    }

    func test_finish_error() {
        // Given
        let delegate = Delegate()
        let backendTracingID = "981d9553578fc280"
        let task = MockURLSessionTask()
        let url = URL.random
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let urlProtocol = InstanaURLProtocol()
        urlProtocol.marker = HTTPMarker(url: url, method: "GET", delegate: delegate)
        let givenError = NSError(domain: NSURLErrorDomain, code: NSURLErrorDataNotAllowed, userInfo: nil)
        var expectedError: NSError?

        // When
        urlProtocol.urlSession(URLSession.shared, task: task, didFinishCollecting: MockURLSessionTaskMetrics.random)
        urlProtocol.urlSession(URLSession.shared, task: task, didCompleteWithError: givenError)

        // Then
        AssertEqualAndNotNil(urlProtocol.marker?.backendTracingID, backendTracingID)
        AssertTrue(delegate.calledFinalized)
        if case let .failed(error) = urlProtocol.marker?.state {
            expectedError = error as NSError
        } else {
            XCTFail("Wrong state for marker")
        }

        AssertEqualAndNotNil(expectedError, givenError)

        if #available(iOS 13.0, *) {
            AssertTrue(urlProtocol.marker?.responseSize?.headerBytes ?? 0 > 0)
        } else {
            AssertTrue(urlProtocol.marker?.responseSize?.headerBytes ?? 0 > 0)
        }
    }

    func test_stop_loading() {
        let delegate = Delegate()
        let url = URL.random
        let urlProtocol = InstanaURLProtocol()
        urlProtocol.marker = HTTPMarker(url: url, method: "GET", delegate: delegate)

        // When
        urlProtocol.stopLoading()

        // Then
        AssertTrue(urlProtocol.marker?.backendTracingID == nil)
        AssertTrue(delegate.calledFinalized)
        guard case .canceled = urlProtocol.marker?.state else {
            XCTFail("Wrong state for marker")
            return
        }
    }

    // MARK: Helper
    class Delegate: HTTPMarkerDelegate {
        var calledFinalized = false
        func finalized(marker: HTTPMarker) {
            calledFinalized = true
        }
    }
}
