import XCTest
@testable import InstanaAgent


class HTTPMarkerTests: InstanaTestCase {

    func test_marker_defaultValues() {
        // Given
        let url: URL = .random
        let start = Date().millisecondsSince1970
        let viewName = URL.random.absoluteString

        // When
        let marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, delegate: Delegate(), viewName: viewName)

        // Then
        XCTAssertEqual(marker.url, url)
        XCTAssertEqual(marker.method, "GET")
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertTrue(marker.startTime >= start)
        XCTAssertEqual(marker.viewName, viewName)
    }

    func test_set_HTTP_Sizes_for_task_and_transactionMetrics() {
        // Given
        let response = MockHTTPURLResponse(url: URL.random, mimeType: "text/plain", expectedContentLength: 1024, textEncodingName: "txt")
        response.stubbedAllHeaderFields = ["KEY": "VALUE"]
        let headerMetric = MockURLSessionTaskTransactionMetrics(stubbedCountOfResponseHeaderBytesReceived: 512)
        let bodyMetric = MockURLSessionTaskTransactionMetrics(stubbedCountOfResponseBodyBytesReceived: 1024)
        let decodedMetric = MockURLSessionTaskTransactionMetrics(stubbedCountOfResponseBodyBytesAfterDecoding: 2000)

        let marker = HTTPMarker(url: URL.random, method: "GET", trigger: .automatic, delegate: Delegate())
        let responseSize = HTTPMarker.Size(response: response, transactionMetrics: [headerMetric, bodyMetric, decodedMetric])

        // When
        marker.set(responseSize: responseSize)

        // Then
        XCTAssertEqual(marker.responseSize?.headerBytes, 512)
        XCTAssertEqual(marker.responseSize?.bodyBytes, 1024)
        XCTAssertEqual(marker.responseSize?.bodyBytesAfterDecoding, 2000)
    }

    func test_set_HTTP_Sizes_for_task() {
        // Given
        let url = URL(string: "https://www.some.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["KEY": "VALUE"])!
        let marker = HTTPMarker(url: url, method: "GET", trigger: .automatic, delegate: Delegate())
        let responseSize = HTTPMarker.Size(response)
        let excpectedHeaderSize = Instana.Types.Bytes(NSKeyedArchiver.archivedData(withRootObject: response.allHeaderFields).count)

        // When
        marker.set(responseSize: responseSize)

        // Then
        AssertEqualAndNotZero(excpectedHeaderSize, 273)
        AssertEqualAndNotZero(marker.responseSize?.headerBytes ?? 0, excpectedHeaderSize)
    }

    func test_finish_200() {
        // Given
        let backendTracingID = "d2f7aebc1ee0813c"
        let delegate = Delegate()
        let response = HTTPURLResponse(url: .random, statusCode: 200, httpVersion: nil, headerFields: ["Server-Timing": "intid;desc=\(backendTracingID)"])
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: delegate, viewName: "SomeView")

        // When
        marker.finish(response: response, error: nil)

        // Then
        XCTAssertEqual(marker.viewName, "SomeView")
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertEqual(delegate.didFinishCount, 1)
        XCTAssertEqual(marker.backendTracingID, backendTracingID)
        if case let .finished(responseCode) = marker.state {
            XCTAssertEqual(responseCode, 200)
        } else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }

    func test_marker_shouldNotRetainDelegate() {
        // Given
        let url: URL = .random
        var delegate: Delegate = Delegate()
        weak var weakDelegate = delegate
        let sut = HTTPMarker(url: url, method: "b", trigger: .automatic, delegate: delegate)
        delegate = Delegate()

        // Then
        XCTAssertNil(weakDelegate)
        XCTAssertEqual(sut.url, url) // random test, so maker is not deallocated and no warning is shown
    }

    func test_unfished_MarkerDuration_shouldBeZero() {
        // Given
        let sut = HTTPMarker(url: .random, method: "b", trigger: .automatic, delegate: Delegate())

        // Then
        XCTAssertEqual(sut.duration, 0)
    }
    
    func test_finish_Marker_withSuccess_shouldRetainOriginalValues() {
        // Given
        let delegate = Delegate()
        let responseSize = HTTPMarker.Size.random
        let marker = HTTPMarker(url: .random, method: "b", trigger: .automatic, delegate: delegate)

        // When
        wait(0.1)
        marker.set(responseSize: responseSize)
        marker.finish(response: createMockResponse(200), error: nil)
        marker.finish(response: createMockResponse(200), error: nil)
        marker.cancel()

        // Then
        XCTAssertEqual(delegate.didFinishCount, 1)
        XCTAssertEqual(marker.responseSize, responseSize)
        XCTAssertTrue(marker.duration > 0)
        if case let .finished(responseCode) = marker.state {
            XCTAssertEqual(responseCode, 200)
        } else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finishing_Marker_withError_shouldRetainOriginalValues() {
        // Given

        let delegate = Delegate()
        let marker = HTTPMarker(url: .random, method: "b", trigger: .automatic, delegate: delegate)
        let error = CocoaError(CocoaError.coderValueNotFound)
        let responseSize = HTTPMarker.Size.random

        // When
        wait(0.1)
        marker.set(responseSize: responseSize)
        marker.finish(response: createMockResponse(200), error: error)
        marker.finish(response: createMockResponse(200), error: CocoaError(CocoaError.coderInvalidValue))
        marker.finish(response: createMockResponse(300), error: nil)

        // Then
        XCTAssertEqual(delegate.didFinishCount, 1)
        XCTAssertEqual(marker.responseSize, responseSize)
        XCTAssertTrue(marker.duration > 0)
        if case let .failed(e) = marker.state {
            XCTAssertEqual(e as? CocoaError, error)
        } else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finishing_Marker_withCancel_shouldRetainOriginalValues() {
        // Given
        let delegate = Delegate()
        let responseSize = HTTPMarker.Size.random
        let marker = HTTPMarker(url: .random, method: "b", trigger: .automatic, delegate: delegate)

        // When
        wait(0.1)
        marker.set(responseSize: responseSize)
        marker.cancel()
        marker.cancel()
        marker.finish(response: createMockResponse(300), error: nil)

        // Then
        XCTAssertEqual(delegate.didFinishCount, 1)
        XCTAssertEqual(marker.responseSize, responseSize)
        XCTAssertTrue(marker.duration > 0)
        if case .canceled = marker.state {} else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }

    // MARK: CreateBeacon
    func test_createBeacon_freshMarker() {
        // Given
        Instana.current?.environment.propertyHandler.properties.view = "Some View"
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "c", trigger: .automatic, delegate: Delegate())

        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.uuidString.count > 0)
        XCTAssertEqual(beacon.viewName, "Some View")
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, 0)
        XCTAssertEqual(beacon.method, "c")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        XCTAssertNil(beacon.responseSize)
        XCTAssertNil(beacon.error)
    }

    func test_createBeacon_finishedMarker() {
        // Given
        let url: URL = .random
        let viewName = URL.random.absoluteString
        let responseSize = HTTPMarker.Size.random
        let marker = HTTPMarker(url: url, method: "m", trigger: .automatic, delegate: Delegate(), viewName: viewName)

        // When
        marker.set(responseSize: responseSize)
        marker.finish(response: createMockResponse(204), error: nil)
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertEqual(beacon.viewName, viewName)
        XCTAssertTrue(beacon.id.uuidString.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "m")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, 204)
        XCTAssertEqual(beacon.responseSize, responseSize)
        XCTAssertNil(beacon.error)
    }
    
    func test_createBeacon_failedMarker() {
        // Given
        let url: URL = .random
        let responseSize = HTTPMarker.Size.random
        let marker = HTTPMarker(url: url, method: "t", trigger: .automatic, delegate: Delegate())
        let error = NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil)

        // When
        marker.set(responseSize: responseSize)
        marker.finish(response: createMockResponse(409), error: error)
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.uuidString.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "t")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        AssertEqualAndNotNil(beacon.responseSize, responseSize)
        AssertEqualAndNotNil(beacon.responseSize?.headerBytes, responseSize.headerBytes)
        AssertEqualAndNotNil(beacon.responseSize?.bodyBytes, responseSize.bodyBytes)
        AssertEqualAndNotNil(beacon.responseSize?.bodyBytesAfterDecoding, responseSize.bodyBytesAfterDecoding)
        XCTAssertEqual(beacon.error, HTTPError.unknown(error))
    }
    
    func test_createBeacon_canceledMarker() {
        // Given
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "c", trigger: .automatic, delegate: Delegate())
        marker.cancel()

        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.uuidString.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "c")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        XCTAssertNil(beacon.responseSize)
        XCTAssertEqual(beacon.error, HTTPError.cancelled)
    }

    // MARK: Helper
    func createMockResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: .random, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

extension HTTPMarkerTests {
    class Delegate: HTTPMarkerDelegate {
        var didFinishCount: Int = 0
        func httpMarkerDidFinish(_ marker: HTTPMarker) {
            didFinishCount += 1
        }
    }
}

