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

    func test_networking_parsesResponseSatusCode() {
        var invocations = 0
        var networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: 200), callback: $1) })
        
        networking.send(request: URLRequest(url: testURL)) {
            invocations += 1
            guard case .success(200) = $0 else { XCTFail("Invalid result"); return }
        }
        
        networking = InstanaNetworking(send: { TestSessionDataTask(response: self.validResponse(statusCode: 204), callback: $1) })
        
        networking.send(request: URLRequest(url: testURL)) {
            invocations += 1
            guard case .success(204) = $0 else { XCTFail("Invalid result"); return }
        }
        
        XCTAssertEqual(invocations, 2)
    }
    
    func test_networkingReturnsError_ifNotAbleToExtractStatusCode() {
        let nonHTTPResponse = URLResponse(url: testURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let networking = InstanaNetworking(send: { TestSessionDataTask(response: nonHTTPResponse, callback: $1) })
        var result: InstanaNetworking.Result?
        
        networking.send(request: URLRequest(url: testURL)) { result = $0 }
        
        XCTAssertNotNil(result)
        guard case let .failure(e)? = result else { XCTFail("Result is not error"); return }
        guard let error = e as? InstanaError else { XCTFail("Error type missmatch"); return }
        XCTAssertEqual(error.code, InstanaError.Code.invalidResponse.rawValue)
    }
    
    func test_networking_forwardsResponseError() {
        let responseError = CocoaError(CocoaError.Code.featureUnsupported)
        let networking = InstanaNetworking(send: { TestSessionDataTask(error: responseError, callback: $1) })
        var result: InstanaNetworking.Result?
        
        networking.send(request: URLRequest(url: testURL)) { result = $0 }
        
        XCTAssertNotNil(result)
        guard case let .failure(e)? = result else { XCTFail("Result is not error"); return }
        guard let error = e as? CocoaError else { XCTFail("Error type missmatch"); return }
        XCTAssertEqual(responseError, error)
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
