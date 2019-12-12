//  Created by Nikola Lajic on 3/20/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor
import WebKit

class InstanaURLProtocolTests: XCTestCase {
    let makeRequest: (String) -> URLRequest = { URLRequest(url: URL(string: $0)!) }

    func test_urlProtocol_disabled_default() {
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

    func test_urlprotocol_with_Webview() {
        // Given
        let givenURL = URL.random
        let didReportWait = expectation(description: "didFinalizeWait")
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
