
import Foundation
import XCTest
import WebKit
@testable import InstanaAgent

@available(iOS 12.0, *)
class InstanaURLProtocolIntegrationTests: InstanaTestCase {

    var givenURL: URL!
    var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        SecondURLProtocol.monitoredURL = nil
        givenURL = .random
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
        Instana.current = Instana(session: session, configuration: session.configuration, monitors: monitors)

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
        Instana.current = Instana(session: session, configuration: session.configuration, monitors: monitors)
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
        Instana.current = Instana(session: session, configuration: session.configuration, monitors: monitors)
        urlSession = URLSession(configuration: URLSessionConfiguration.default)

        // When
        urlSession.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(resultBeacon?.url, givenURL)
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
}
