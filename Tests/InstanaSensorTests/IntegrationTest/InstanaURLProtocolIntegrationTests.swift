
import Foundation
import XCTest
import WebKit
@testable import InstanaSensor

@available(iOS 12.0, *)
class InstanaURLProtocolIntegrationTests: IntegrationTestCase {
    func test_urlprotocol_with_shared_URLSession_mock_report() {
        // Given
        let givenURL = Defaults.someURL
        let didReportWait = expectation(description: "didFinish")
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, reportingType: .automatic)
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(config, reporter: mockReporter)
        Instana.current = Instana(configuration: config, monitors: monitors)

        // When
        URLSession.shared.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 1.4)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }

    func test_urlprotocol_with_custom_URLSession_mock_report() {
        // Given
        let givenURL = Defaults.someURL
        let didReportWait = expectation(description: "didFinish")
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, reportingType: .automatic)
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(config, reporter: mockReporter)
        Instana.current = Instana(configuration: config, monitors: monitors)
        session = URLSession(configuration: URLSessionConfiguration.default)

        // When
        session.dataTask(with: givenURL) {_, _, _ in}.resume()
        wait(for: [didReportWait], timeout: 1.4)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }

    func test_urlprotocol_with_Webview_mock_report() {
        // Given
        let givenURL = Defaults.someURL
        let didReportWait = expectation(description: "didFinish")
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, reportingType: .automatic)
        var expectedBeacon: HTTPBeacon?
        let mockReporter = MockReporter { submittedBeacon in
            if let httpBeacon = submittedBeacon as? HTTPBeacon {
                expectedBeacon = httpBeacon
                didReportWait.fulfill()
            }
        }
        let monitors = Monitors(config, reporter: mockReporter)
        Instana.current = Instana(configuration: config, monitors: monitors)
        let webView = WKWebView()

        // When
        webView.load(URLRequest(url: givenURL))
        wait(for: [didReportWait], timeout: 1.4)

        // Then
        AssertEqualAndNotNil(expectedBeacon?.url, givenURL)
    }
}
