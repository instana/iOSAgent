//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
import WebKit
@testable import InstanaAgent

@available(iOS 12.0, *)
class InstanaURLProtocolIntegrationTests: InstanaTestCase {

    var givenURL: URL!
    var urlSession: URLSession!
    var customURLSessionDelegate: CustomURLSessionDelegate?

    override func setUp() {
        super.setUp()
        SecondURLProtocol.monitoredURL = nil
        givenURL = .random
        customURLSessionDelegate = CustomURLSessionDelegate()
    }

    func test_urlprotocol_with_shared_URLSession_mock_report() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var resultBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                resultBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(session, reporter: mockReporter)
        Instana.current = Instana(session: session, monitors: monitors)

        // When
        URLSession.shared.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(resultBeacon?.url, givenURL)
    }

    func test_second_urlProtocol_in_use() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var resultBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                resultBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(session, reporter: mockReporter)
        Instana.current = Instana(session: session, monitors: monitors)
        let config = URLSessionConfiguration.default
        config.protocolClasses?.insert(SecondURLProtocol.self, at: 0)
        urlSession = URLSession(configuration: config)

        // When
        urlSession.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(resultBeacon?.url, givenURL)
        AssertEqualAndNotNil(SecondURLProtocol.monitoredURL, givenURL)
    }

    func test_urlprotocol_with_custom_URLSession_mock_report() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var resultBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                resultBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(session, reporter: mockReporter)
        Instana.current = Instana(session: session, monitors: monitors)
        urlSession = URLSession(configuration: URLSessionConfiguration.default)

        // When
        urlSession.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(resultBeacon?.url, givenURL)
    }

    // MARK: - URLSession Delegates
    func test_didBecomeInvalidWithError() {
        // Given
        let didReportWait = expectation(description: "test_didBecomeInvalidWithError")
        Instana.current = Instana(session: session)
        let urlSession = URLSession(configuration: .default, delegate: customURLSessionDelegate, delegateQueue: nil)
        var passed = false
        customURLSessionDelegate?.passedDidBecomeInvalidWithError = {result in
            passed = result
            didReportWait.fulfill()
        }

        // When
        urlSession.dataTask(with: givenURL) {_, _, _ in}.resume()
        urlSession.invalidateAndCancel()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertTrue(passed)
    }

    // MARK: Helper
    class SecondURLProtocol: URLProtocol {
        static var monitoredURL: URL?
        override class func canInit(with request: URLRequest) -> Bool {
            monitoredURL = request.url
            return true
        }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            monitoredURL = request.url
            return request
        }

        override func startLoading() {
            client?.urlProtocolDidFinishLoading(self)
        }
        override func stopLoading() {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
        var passedDidBecomeInvalidWithError: ((Bool) -> Void)?
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            passedDidBecomeInvalidWithError?(true)
        }
    }
}
