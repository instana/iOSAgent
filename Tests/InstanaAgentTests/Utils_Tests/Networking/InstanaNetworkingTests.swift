import XCTest
@testable import InstanaAgent

class InstanaNetworkingTests: InstanaTestCase {
    
    let testURL = URL(string: "www.a.a")!

    func test_networking_load() {
        let networking = InstanaNetworking(send: { _, resultCallback -> URLSessionDataTask in
            return TestSessionDataTask(response: self.validResponse(statusCode: 204), callback: resultCallback)
        })
        var loaded = false
        
        networking.send(request: URLRequest(url: testURL)) { _ in
            loaded = true
        }
        
        XCTAssertTrue(loaded, "Load never invoked callback")
    }

    func test_networking_parsesResponseSatusCode_ok() {
        var invocations = 0
        let randomOK: Int = (200...299).randomElement() ?? 200
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: randomOK), callback: $1) })
        networking.send(request: URLRequest(url: testURL)) {
            if case .success(randomOK) = $0 {
                invocations += 1
            } else { XCTFail("Invalid result \($0)"); return }
        }

        XCTAssertEqual(invocations, 1)
    }

    func test_networking_parsesResponseSatusCode_http_client_error() {
        var invocations = 0
        let random400: Int = (400...499).randomElement() ?? 400
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: random400), callback: $1) })
        networking.send(request: URLRequest(url: testURL)) {
            if case .failure(InstanaError.httpClientError(random400)) = $0 {
                invocations += 1
            } else { XCTFail("Invalid result \($0)"); return }
        }

        XCTAssertEqual(invocations, 1)
    }

    func test_networking_parsesResponseSatusCode_http_server_error() {
        var invocations = 0
        let random500: Int = (500...599).randomElement() ?? 500
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: random500), callback: $1) })
        networking.send(request: URLRequest(url: testURL)) {
            if case .failure(InstanaError.httpServerError(random500)) = $0 {
                invocations += 1
            } else { XCTFail("Invalid result \($0)"); return }
        }

        XCTAssertEqual(invocations, 1)
    }

    func test_networking_parsesResponseSatusCode_invalid_response() {
        var invocations = 0
        let random500: Int = (600...699).randomElement() ?? 600
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: random500), callback: $1) })
        networking.send(request: URLRequest(url: testURL)) {
            if case .failure(InstanaError.invalidResponse) = $0 {
                invocations += 1
            } else { XCTFail("Invalid result \($0)"); return }
        }

        XCTAssertEqual(invocations, 1)
    }
    
    func test_networkingReturnsError_ifNotAbleToExtractStatusCode() {
        let nonHTTPResponse = URLResponse(url: testURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: nonHTTPResponse, callback: $1) })
        var result: InstanaNetworking.Result?
        
        networking.send(request: URLRequest(url: testURL)) { result = $0 }
        
        XCTAssertNotNil(result)
        guard case let .failure(e)? = result else { XCTFail("Result is not error"); return }
        guard let error = e as? InstanaError else { XCTFail("Error type missmatch"); return }
        XCTAssertEqual(error, InstanaError.invalidResponse)
    }
    
    func test_networking_forwardsResponseError() {
        let responseError = CocoaError(CocoaError.Code.featureUnsupported)
        let networking = InstanaNetworking(send: { TestSessionDataTask(error: responseError, callback: $1) })
        var result: InstanaNetworking.Result?
        
        networking.send(request: URLRequest(url: testURL)) { result = $0 }
        
        XCTAssertNotNil(result)
        guard case let .failure(e)? = result else { XCTFail("Result is not error"); return }
        guard let error = e as? InstanaError else { XCTFail("Error is not InstanaError"); return }
        guard case let InstanaError.underlying(underlyingE) = error else { XCTFail("Error is not InstanaError underlying"); return }
        XCTAssertEqual(underlyingE as? CocoaError, responseError)
    }
}

extension InstanaNetworkingTests {
    private class TestSessionDataTask: URLSessionDataTask {
        let callback: InstanaNetworking.DataTaskResult
        let testData: Data?
        let testResponse: URLResponse?
        let testError: Error?
        
        init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, callback: @escaping InstanaNetworking.DataTaskResult) {
            self.testData = data
            self.testResponse = response
            self.testError = error
            self.callback = callback
            super.init()
        }
        
        override func resume() {
            callback(testData, testResponse, testError)
        }
    }
    
    func validResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: testURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
