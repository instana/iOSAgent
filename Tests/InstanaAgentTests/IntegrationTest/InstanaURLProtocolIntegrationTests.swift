
import Foundation
import XCTest
import WebKit
@testable import InstanaAgent

@available(iOS 12.0, *)
class InstanaURLProtocolIntegrationTests: IntegrationTestCase {

    var env: InstanaEnvironment!
    var givenURL: URL!

    override func setUp() {
        super.setUp()
        env = InstanaEnvironment.mock
        givenURL = Defaults.someURL
    }

    func test_urlprotocol_with_shared_URLSession_mock_report() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(env, reporter: mockReporter)
        Instana.current = Instana(configuration: env.configuration, monitors: monitors)

        // When
        URLSession.shared.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }

    func test_urlprotocol_with_custom_URLSession_mock_report() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(env, reporter: mockReporter)
        Instana.current = Instana(configuration: env.configuration, monitors: monitors)
        session = URLSession(configuration: URLSessionConfiguration.default)

        // When
        session.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }

    func test_urlprotocol_with_Webview_mock_report() {
        // Given
        let didReportWait = expectation(description: "didFinish")
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(env, reporter: mockReporter)
        Instana.current = Instana(configuration: env.configuration, monitors: monitors)
        let webView = WKWebView()

        // When
        webView.load(URLRequest(url: givenURL))
        wait(for: [didReportWait], timeout: 10)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }
}
