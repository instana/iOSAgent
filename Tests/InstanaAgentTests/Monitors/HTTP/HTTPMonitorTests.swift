import XCTest
@testable import InstanaAgent

class HTTPMonitorTests: InstanaTestCase {

    func test_reporting_url_ignored() {
        // Given
        let reportingURL = session.configuration.reportingURL

        // When
        _ = HTTPMonitor(session, reporter: instana.monitors.reporter)

        // Then
        AssertTrue(IgnoreURLHandler.shouldIgnore(reportingURL))
        AssertTrue(IgnoreURLHandler.exactURLs.count == 1)
        AssertTrue(IgnoreURLHandler.exactURLs.first == reportingURL)
    }

    func test_load_default_DefaultIgnoredURLs() {
        // When
        _ = HTTPMonitor(session, reporter: instana.monitors.reporter)

        // Then
        AssertTrue(IgnoreURLHandler.shouldIgnore(URL(string: "https://api.instabug.com/some")!))
        AssertTrue(IgnoreURLHandler.shouldIgnore(URL(string: "https://some.instabug.com/some")!))
        AssertFalse(IgnoreURLHandler.shouldIgnore(URL(string: "https://some.instabug.de/some")!))
    }

    func test_init_automatic_reporting() {
        var installed: AnyClass?
        var uninstalled: AnyClass?

        // Before
        AssertTrue(IgnoreURLHandler.exactURLs.count == 0)
        AssertTrue(IgnoreURLHandler.regex.count == 0)

        // When
        _ = HTTPMonitor(InstanaSession.mockWithAutomaticHTTPCapture,
                        installer: { result in
                            installed = result
                            return true
                        }, uninstaller: { result in
                            uninstalled = result
                        }, reporter: instana.monitors.reporter)
        
        // Then
        AssertTrue(installed != nil)
        AssertTrue(uninstalled == nil)
        AssertTrue(IgnoreURLHandler.exactURLs.count > 0)
        AssertTrue(IgnoreURLHandler.regex.count > 0)
    }

    func test_init_automaticAndManual_reporting() {
        var installed: AnyClass?
        var uninstalled: AnyClass?

        // Before
        AssertTrue(IgnoreURLHandler.exactURLs.count == 0)
        AssertTrue(IgnoreURLHandler.regex.count == 0)

        // When
        _ = HTTPMonitor(InstanaSession.mockWithAutomaticAndManualHTTPCapture,
                        installer: { result in
                            installed = result
                            return true
                        }, uninstaller: { result in
                            uninstalled = result
                        }, reporter: instana.monitors.reporter)

        // Then
        AssertTrue(installed != nil)
        AssertTrue(uninstalled == nil)
        AssertTrue(IgnoreURLHandler.exactURLs.count > 0)
        AssertTrue(IgnoreURLHandler.regex.count > 0)
    }

    func test_init_manual_reporting() {
        var installed: AnyClass?
        var uninstalled: AnyClass?

        // Before
        AssertTrue(IgnoreURLHandler.exactURLs.count == 0)
        AssertTrue(IgnoreURLHandler.regex.count == 0)

        // When
        _ = HTTPMonitor(InstanaSession.mockWithManualHTTPCapture,
                        installer: { result in
                            installed = result
                            return true
                        }, uninstaller: { result in
                            uninstalled = result
                        }, reporter: instana.monitors.reporter)

        // Then
        AssertTrue(installed == nil)
        AssertTrue(uninstalled != nil)
        AssertTrue(IgnoreURLHandler.exactURLs.count > 0)
        AssertTrue(IgnoreURLHandler.regex.count > 0)
    }

    func test_init_none_reporting() {
        var installed: AnyClass?
        var uninstalled: AnyClass?

        // Before
        AssertTrue(IgnoreURLHandler.exactURLs.count == 0)
        AssertTrue(IgnoreURLHandler.regex.count == 0)

        // When
        _ = HTTPMonitor(InstanaSession.mockWithNoneHTTPCapture,
                        installer: { result in
                            installed = result
                            return true
                        }, uninstaller: { result in
                            uninstalled = result
                        }, reporter: instana.monitors.reporter)

        // Then
        AssertTrue(installed == nil)
        AssertTrue(uninstalled != nil)
        AssertTrue(IgnoreURLHandler.exactURLs.count > 0)
        AssertTrue(IgnoreURLHandler.regex.count > 0)
    }

    func test_installing_shouldAddCustomProtocol() {
        var installed = false
        let monitor = HTTPMonitor(session, installer: {
            AssertTrue($0 == InstanaURLProtocol.self)
            installed = true
            return true
        }, reporter: instana.monitors.reporter)

        // When
        monitor.install()
        _ = URLSession(configuration: URLSessionConfiguration.default)

        // Then
        let allURLProtocolClasses = URLSessionConfiguration.all.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(installed)
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})
    }
    
    func test_uninstalling_shouldRemoveCustomProtocol() {
        var deinstall = false
        let monitor = HTTPMonitor(session, uninstaller: {
            AssertTrue($0 == InstanaURLProtocol.self)
            deinstall = true
        }, reporter: instana.monitors.reporter)

        // When
        _ = URLSession(configuration: URLSessionConfiguration.default)

        // Then
        var allURLProtocolClasses = URLSessionConfiguration.all.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})

        // When
        monitor.deinstall()

        // Then
        allURLProtocolClasses = URLSessionConfiguration.all.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(deinstall)
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self} == false)
    }

    func test_installingInConfiguration_shouldAddCustomProtocol() {
        // Given
        let monitor = HTTPMonitor(session, reporter: instana.monitors.reporter)
        let sessionConfig = URLSessionConfiguration.default

        // When
        monitor.install()

        // Then
        XCTAssertFalse(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? true)
        sessionConfig.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
        XCTAssertTrue(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? false)
    }

    func test_markingRequest() {
        // Given
        let url: URL = .random
        let monitor = HTTPMonitor(session, reporter: instana.monitors.reporter)
        var request = URLRequest(url: url)
        request.httpMethod = "m"
        request.httpBody = "11".data(using: .utf8)

        // When
        let marker = try! monitor.mark(request)

        // Then
        XCTAssertEqual(marker.url, url)
        XCTAssertEqual(marker.method, "m")
        XCTAssertEqual(marker.trigger, .automatic)
    }
    
    func test_invalid_request() {
        // Given
        let url: URL = .random
        let monitor = HTTPMonitor(session, reporter: instana.monitors.reporter)
        var request = URLRequest(url: url)
        request.url = nil
        request.httpMethod = nil

        // When
        XCTAssertThrowsError(try monitor.mark(request)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError), InstanaError.invalidRequest)
        }
    }

    func test_httpMarkerDidFinish() {
        // Given
        var expectedBeacon: HTTPBeacon?
        session.propertyHandler.properties.view = "SomeView"
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: nil)
        let monitor = HTTPMonitor(session, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertEqualAndNotNil(marker.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.url, marker.url)
    }

    func test_httpMarkerDidFinish_with_matching_header() {
        // Given
        var expectedBeacon: HTTPBeacon?
        session.propertyHandler.properties.view = "SomeView"
        let header = ["X-K": "Val"]
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, header: header, delegate: nil)
        let monitor = HTTPMonitor(session, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })
        monitor.filter.headerFieldsRegEx.append(try! NSRegularExpression(pattern: "X-K"))

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertEqualAndNotNil(marker.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.url, marker.url)
        AssertEqualAndNotNil(expectedBeacon?.header?["X-K"], "Val")
    }

    func test_httpMarkerDidFinish_with_non_matching_header() {
        // Given
        var expectedBeacon: HTTPBeacon?
        session.propertyHandler.properties.view = "SomeView"
        let header = ["X-K": "Val"]
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, header: header, delegate: nil)
        let monitor = HTTPMonitor(session, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })
        monitor.filter.headerFieldsRegEx.append(try! NSRegularExpression(pattern: "non-match"))

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertEqualAndNotNil(marker.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.viewName, "SomeView")
        AssertEqualAndNotNil(expectedBeacon?.url, marker.url)
        AssertEqualAndNotNil(expectedBeacon?.header?.count, 0)
    }

    func test_httpMarkerDidFinish_viewName_explicitly_given() {
        // Given
        var expectedBeacon: HTTPBeacon?
        session.propertyHandler.properties.view = nil
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, header: nil, delegate: nil, viewName: "MoreView")
        let monitor = HTTPMonitor(session, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertEqualAndNotNil(marker.viewName, "MoreView")
        AssertEqualAndNotNil(expectedBeacon?.viewName, "MoreView")
        AssertEqualAndNotNil(expectedBeacon?.url, marker.url)
    }

    func test_httpMarkerDidFinish_should_not_report() {
        // Marker has been triggered automatically - but session allows only manual capturing
        Instana.current?.session.propertyHandler.properties.view = "SomeView"
        var expectedBeacon: HTTPBeacon?
        let marker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, header: nil, delegate: nil)
        let monitor = HTTPMonitor(InstanaSession.mockWithManualHTTPCapture, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertTrue(monitor.shouldReport(marker) == false)
        AssertTrue(marker.viewName != "SomeView")
        XCTAssertNil(expectedBeacon)
    }

    func test_httpMarkerDidFinish_should_report_AutomaticAndManual() {
        // Marker has been triggered automatically - but session allows both (manual and automatic) capturing
        var expectedBeacon: HTTPBeacon?
        let marker = HTTPMarker(url: .random, method: "GET", trigger: [.automatic, .manual].randomElement()!, delegate: nil)
        let monitor = HTTPMonitor(InstanaSession.mockWithAutomaticAndManualHTTPCapture, reporter: MockReporter { submittedBeacon in
            expectedBeacon = submittedBeacon as? HTTPBeacon
        })

        // When
        monitor.httpMarkerDidFinish(marker)

        // Then
        AssertTrue(monitor.shouldReport(marker))
        AssertEqualAndNotNil(expectedBeacon?.url, marker.url)
    }

    func test_should_report_with_automatic_monitoring() {
        // Only automatic triggered should be tracked

        // Given
        let monitor = HTTPMonitor(InstanaSession.mockWithAutomaticHTTPCapture, reporter: MockReporter())

        // When
        let automaticTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: nil)

        // Then
        AssertTrue(monitor.shouldReport(automaticTriggeredMarker))

        // When
        let manualTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .manual, delegate: nil)

        // Then
        XCTAssertFalse(monitor.shouldReport(manualTriggeredMarker))
    }

    func test_should_report_with_manual_monitoring() {
        // Only manual should be tracked

        // Given
        let monitor = HTTPMonitor(InstanaSession.mockWithManualHTTPCapture, reporter: MockReporter())

        // When
        let automaticTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: nil)

        // Then
        XCTAssertFalse(monitor.shouldReport(automaticTriggeredMarker))

        // When
        let manualTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .manual, delegate: nil)

        // Then
        AssertTrue(monitor.shouldReport(manualTriggeredMarker))
    }

    func test_should_report_with_automaticAndManual_monitoring() {
        // Only manual should be tracked

        // Given
        let monitor = HTTPMonitor(InstanaSession.mockWithAutomaticAndManualHTTPCapture, reporter: MockReporter())

        // When
        let automaticTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: nil)

        // Then
        AssertTrue(monitor.shouldReport(automaticTriggeredMarker))

        // When
        let manualTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .manual, delegate: nil)

        // Then
        AssertTrue(monitor.shouldReport(manualTriggeredMarker))
    }

    func test_should_report_with_none_monitoring() {
        // No http request should be tracked

        // Given
        let monitor = HTTPMonitor(InstanaSession.mockWithNoneHTTPCapture, reporter: MockReporter())

        // When
        let automaticTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .automatic, delegate: nil)

        // Then
        XCTAssertFalse(monitor.shouldReport(automaticTriggeredMarker))

        // When
        let manualTriggeredMarker = HTTPMarker(url: .random, method: "GET", trigger: .manual, delegate: nil)

        // Then
        XCTAssertFalse(monitor.shouldReport(manualTriggeredMarker))
    }
    
    func test_automaticTriggerMarker_shouldBeReportedOnlyForAutomatedReporting() {
        // Given
        var config = InstanaConfiguration.mock(key: "KEY")
        var count = 0

        // Automatic
        // When
        config.httpCaptureConfig = .automatic
        var monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .automatic))

        // Then
        XCTAssertEqual(count, 1)

        // When Automatic And manual
        config.httpCaptureConfig = .automatic
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .automatic))

        // Then
        XCTAssertEqual(count, 2)

        // When Manual capture
        config.httpCaptureConfig = .manual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .automatic))

        // Then
        XCTAssertEqual(count, 2)

        // When No http capture
        config.httpCaptureConfig = .none
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .automatic))

        // Then
        XCTAssertEqual(count, 2)
    }
    
    func test_manualTriggerMarker_shouldBeReportedOnlyForManualReporting() {
        // Given
        var config = InstanaConfiguration.mock(key: "KEY")
        var count = 0

        // When automatic capture
        config.httpCaptureConfig = .automatic
        var monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .manual))

        // Then
        XCTAssertEqual(count, 0)

        // When manual capture
        config.httpCaptureConfig = .manual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .manual))

        // Then
        XCTAssertEqual(count, 1)

        // When deactivated
        config.httpCaptureConfig = .none
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .manual))

        // Then
        XCTAssertEqual(count, 1)
    }

    func test_manualTriggerMarker_shouldBeReportedForAutomaticAndManualReporting() {
        // Given
        var config = InstanaConfiguration.mock(key: "KEY")
        var count = 0

        // When automatic capture
        config.httpCaptureConfig = .automaticAndManual
        var monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .automatic))

        // Then
        XCTAssertEqual(count, 1)

        // When manual capture
        config.httpCaptureConfig = .automaticAndManual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .manual))

        // Then
        XCTAssertEqual(count, 2)

        // When deactivated
        config.httpCaptureConfig = .none
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.httpMarkerDidFinish(Random.marker(monitor, trigger: .manual))

        // Then
        XCTAssertEqual(count, 2)
    }

    struct Random {
        static func marker(_ monitor: HTTPMonitor, trigger: HTTPMarker.Trigger) -> HTTPMarker { HTTPMarker(url: URL.random, method: "GET", trigger: trigger, delegate: monitor) }
    }
}
