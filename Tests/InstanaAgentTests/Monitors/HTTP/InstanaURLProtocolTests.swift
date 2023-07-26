import XCTest
@testable import InstanaAgent

class InstanaURLProtocolTests: InstanaTestCase {

    override func setUp() {
        super.setUp()
        URLSessionConfiguration.removeAllInstanaURLProtocol()
    }

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
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("some:nohost")))
    }

    func test_urlProtocol_shouldNotInitForBase64() {
        // Given
        let base64 = "data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAwBQTFRF7c5J78kt+/Xm78lQ6stH5LI36bQh6rcf7sQp67="
        let request = makeRequest(base64)

        // Then
        XCTAssertFalse(InstanaURLProtocol.canInit(with:request))
        XCTAssertEqual(request.url?.absoluteString, base64)
    }

    func test_urlProtocol_shouldNotInitForIgnoredURL() {
        // Given
        InstanaURLProtocol.mode = .enabled

        // When
        IgnoreURLHandler.exactURLs = AtomicSet([URL(string: "https://www.url.to/ignore")!])

        // Then
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("https://www.url.to/ignore")))
    }

    func test_urlProtocol_shouldNotInitForIgnoredURLRegex() {
        // Given
        InstanaURLProtocol.mode = .enabled

        // When
        let regex = try! NSRegularExpression(pattern: ".*(&|\\?)password=.*")
        IgnoreURLHandler.regex = AtomicSet([regex])

        // Then
        XCTAssertFalse(InstanaURLProtocol.canInit(with: makeRequest("https://www.a.b/?password=abc")))
    }
    
    func test_urlProtocol_shouldNotModifyCanonicalRequest() {
        // Given
        let request = makeRequest("http://www.test.com")

        // When
        let cannonialRequest = InstanaURLProtocol.canonicalRequest(for: request)

        // Then
        XCTAssertEqual(request, cannonialRequest)
    }

    func test_startLoading_enabled() {
        // Given
        let url = URL.random
        InstanaURLProtocol.mode = .enabled
        let urlProtocol = InstanaURLProtocol(task: mockTask(for: url), cachedResponse: nil, client: nil)

        // When
        urlProtocol.startLoading()

        // Then
        AssertEqualAndNotNil(urlProtocol.marker?.url, url)
    }

    func test_startLoading_disabled() {
        // Given
        let url = URL.random
        InstanaURLProtocol.mode = .disabled
        let urlProtocol = InstanaURLProtocol(task: mockTask(for: url), cachedResponse: nil, client: nil)

        // When
        urlProtocol.startLoading()

        // Then
        AssertTrue(urlProtocol.marker == nil)
    }

    func test_startLoading_enabled_but_session_is_ignored() {
        // Given
        let url = "http://www.a.c"
        InstanaURLProtocol.mode = .enabled
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: makeRequest(url))
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)

        // When
        IgnoreURLHandler.urlSessions.insert(session)
        urlProtocol.startLoading()

        // Then
        AssertTrue(urlProtocol.marker == nil)
    }

    func test_urlProtocol_shouldExtractInternalTaskSessionConfiguration() {
        // Given
        let timeout = 123.2
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        let request = URLRequest(url: URL.random, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: timeout)
        let task = URLSession(configuration: configuration).dataTask(with: request)

        // When
        let urlProtocol = InstanaURLProtocol(task: task, cachedResponse: nil, client: nil)

        // Then
        AssertEqualAndNotNil(urlProtocol.sessionConfiguration.timeoutIntervalForRequest, timeout)
    }
    
    func test_urlProtocol_shouldRemoveSelfFromCopiedInternalTaskSessionConfiguration() {
        // Given
        let configuration = URLSessionConfiguration.default

        // When
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
        let urlProtocol = InstanaURLProtocol(task: mockTask(for: URL.random), cachedResponse: nil, client: nil)

        // When
        let protocolClasses = urlProtocol.sessionConfiguration.protocolClasses ?? []
        XCTAssertFalse(protocolClasses.contains { $0 == InstanaURLProtocol.self })
    }

    func test_swizzle_and_install_custom_urlSession_urlprotocol() {
        // Given
        InstanaURLProtocol.install
        let config = URLSessionConfiguration.default

        // When
        let session = URLSession(configuration: config) // The actual swizzling is done here
        let sessionURLProtocols = session.configuration.protocolClasses ?? []

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})
        AssertTrue(sessionURLProtocols.contains {$0 == InstanaURLProtocol.self})
    }

    func test_swizzle_and_install_custom_urlSession_urlprotocol_2() {
        // Given
        InstanaURLProtocol.install
        let config = URLSessionConfiguration.default

        // When
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let sessionURLProtocols = session.configuration.protocolClasses ?? []

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})
        AssertTrue(sessionURLProtocols.contains {$0 == InstanaURLProtocol.self})
    }

    func test_do_not_swizzle_for_any_URLProtocol_as_delegate() {
        // Given
        class CustomURLProtocol: URLProtocol, URLSessionDelegate {}
        InstanaURLProtocol.install
        let delegate = CustomURLProtocol()

        // When
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)
        let sessionURLProtocols = session.configuration.protocolClasses ?? []

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == CustomURLProtocol.self} == false)
        AssertTrue(sessionURLProtocols.contains {$0 == CustomURLProtocol.self} == false)
    }

    // Done without the Swizzle
    func test_store_and_install_urlProtocol() {
        // Given
        let config = URLSessionConfiguration.default

        // When
        InstanaURLProtocol.install
        config.registerInstanaURLProtocol()

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains(where: {$0 == InstanaURLProtocol.self}))
        AssertTrue(URLSessionConfiguration.all.contains {$0 == config})
    }

    func test_remove_all_urlprotocols() {
        // Given
        let config = URLSessionConfiguration.default
        InstanaURLProtocol.install
        config.registerInstanaURLProtocol()

        // When
        URLSessionConfiguration.removeAllInstanaURLProtocol()

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap {$0.protocolClasses}.flatMap {$0}
        AssertTrue(URLSessionConfiguration.all.contains {$0 == config} == false)
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self} == false)
    }

    func test_remove_one_urlprotocols() {
        // Given
        let config = URLSessionConfiguration.default
        InstanaURLProtocol.install
        config.registerInstanaURLProtocol()

        // When
        config.removeInstanaURLProtocol()

        // Then
        AssertTrue(URLSessionConfiguration.all.contains {$0 == config} == false)
        AssertTrue(config.protocolClasses?.contains {$0 == InstanaURLProtocol.self} == false)
    }

    // Integration Tests
    func test_finish_success() {
        // Given
        let headerFilterRegex = try! NSRegularExpression(pattern: "X-Key", options: .caseInsensitive)
        Instana.setCaptureHeaders(matching: [headerFilterRegex])

        let waitFor = expectation(description: "Wait for")
        let delegate = Delegate()
        let backendTracingID = "981d9553578fc280"
        let url = URL.random
        let task = MockURLSessionTask()
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let metrics = MockURLSessionTaskMetrics.random
        let header = ["X-Key": "Value"]
        let urlProtocol = InstanaURLProtocol(task: mockTask(for: url), cachedResponse: nil, client: nil)
        let marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, header: header, delegate: delegate)
        urlProtocol.marker = marker

        // When
        urlProtocol.urlSession(URLSession.shared, task: task, didFinishCollecting: metrics)
        urlProtocol.urlSession(URLSession.shared, task: task, didCompleteWithError: nil)
        urlProtocol.markerQueue.async {
            waitFor.fulfill()
        }

        // Then
        wait(for: [waitFor], timeout: 3.0)
        AssertEqualAndNotNil(urlProtocol.marker?.backendTracingID, backendTracingID)
        AssertEqualAndNotNil(urlProtocol.marker, marker)
        AssertEqualAndNotNil(urlProtocol.marker?.header, header)
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
        let delegate = Delegate()
        let waitFor = expectation(description: "Wait For")
        let backendTracingID = "981d9553578fc280"
        let url = URL.random
        let task = MockURLSessionTask()
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedStatusCode = 301
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let urlProtocol = InstanaURLProtocol(task: mockTask(for: url), cachedResponse: nil, client: nil)
        let marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, delegate: delegate)
        urlProtocol.marker = marker
        let newRequest = URLRequest(url: URL.random)
        var resultCompletionRequest: URLRequest?

        // When perfom the HTTP Forward
        urlProtocol.urlSession(URLSession.shared, task: task, willPerformHTTPRedirection: response, newRequest: newRequest) { comingRequest in
            resultCompletionRequest = comingRequest
            waitFor.fulfill()
        }

        // Then
        wait(for: [waitFor], timeout: 3.0)
        AssertEqualAndNotNil(marker.backendTracingID, backendTracingID)
        AssertEqualAndNotNil(resultCompletionRequest, newRequest)
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
        let waitFor = expectation(description: "Wait for")
        let delegate = Delegate()
        let backendTracingID = "981d9553578fc280"
        let task = MockURLSessionTask()
        let url = URL.random
        let header = ["X-Key": "Val"]
        let response = MockHTTPURLResponse(url: url, mimeType: "text/plain", expectedContentLength: 10, textEncodingName: "txt")
        response.stubbedAllHeaderFields = ["Server-Timing": "intid;desc=981d9553578fc280"]
        task.stubbedResponse = response
        let urlProtocol = InstanaURLProtocol(request: URLRequest(url: url), cachedResponse: nil, client: nil)
        urlProtocol.marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, header: header, delegate: delegate)
        let givenError = NSError(domain: NSURLErrorDomain, code: NSURLErrorDataNotAllowed, userInfo: nil)
        var resultError: NSError?

        // When
        urlProtocol.urlSession(URLSession.shared, task: task, didFinishCollecting: MockURLSessionTaskMetrics.random)
        urlProtocol.urlSession(URLSession.shared, task: task, didCompleteWithError: givenError)
        urlProtocol.markerQueue.async {
            waitFor.fulfill()
        }

        // Then
        wait(for: [waitFor], timeout: 3.0)
        AssertEqualAndNotNil(urlProtocol.marker?.backendTracingID, backendTracingID)
        AssertTrue(delegate.calledFinalized)
        if case let .failed(error) = urlProtocol.marker?.state {
            resultError = error as NSError
        } else {
            XCTFail("Wrong state for marker")
        }

        AssertEqualAndNotNil(resultError, givenError)

        if #available(iOS 13.0, *) {
            AssertTrue(urlProtocol.marker?.responseSize?.headerBytes ?? 0 > 0)
        } else {
            AssertTrue(urlProtocol.marker?.responseSize?.headerBytes ?? 0 > 0)
        }
    }

    func test_stop_loading() {
        let waitFor = expectation(description: "Wait For")
        let delegate = Delegate()
        let url = URL.random
        let urlProtocol = InstanaURLProtocol(request: URLRequest(url: url), cachedResponse: nil, client: nil)
        urlProtocol.marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, delegate: delegate)

        // When
        urlProtocol.stopLoading()
        urlProtocol.markerQueue.async {
            waitFor.fulfill()
        }

        // Then
        wait(for: [waitFor], timeout: 3.0)
        AssertTrue(urlProtocol.marker?.backendTracingID == nil)
        AssertTrue(delegate.calledFinalized)
        guard case .canceled = urlProtocol.marker?.state else {
            XCTFail("Wrong state for marker")
            return
        }
    }

    // MARK: Helper

    func mockTask(for url: URL) -> URLSessionTask {
        URLSession(configuration: .default).dataTask(with: url)
    }

    func makeRequest(_ url: String) -> URLRequest {
        URLRequest(url: URL(string: url)!)
    }

    class Delegate: HTTPMarkerDelegate {
        var calledFinalized = false
        func httpMarkerDidFinish(_ marker: HTTPMarker) { calledFinalized = true }
    }
}
