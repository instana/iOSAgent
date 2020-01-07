import XCTest
@testable import InstanaSensor

class HTTPMonitorTests: XCTestCase {

    var env: InstanaEnvironment!
    var instana: Instana!

    override func setUp() {
        super.setUp()
        Instana.setup(key: "KEY123")
        instana = Instana.current
        env = instana.environment
    }

    override func tearDown() {
        super.tearDown()
        self.instana = nil
    }

    func test_installing_shouldAddCustomProtocol() {
        var installed = false
        let monitor = HTTPMonitor(env, installer: {
            AssertTrue($0 == InstanaURLProtocol.self)
            installed = true
            return true
        }, reporter: instana.monitors.reporter)

        // When
        monitor.install()
        _ = URLSession(configuration: URLSessionConfiguration.default)

        // Then
        let allURLProtocolClasses = URLSession.allSessionConfigs.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(installed)
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})
    }
    
    func test_uninstalling_shouldRemoveCustomProtocol() {
        var deinstall = false
        let monitor = HTTPMonitor(env, uninstaller: {
            AssertTrue($0 == InstanaURLProtocol.self)
            deinstall = true
        }, reporter: instana.monitors.reporter)

        // When
        _ = URLSession(configuration: URLSessionConfiguration.default)

        // Then
        var allURLProtocolClasses = URLSession.allSessionConfigs.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self})

        // When
        monitor.deinstall()

        // Then
        allURLProtocolClasses = URLSession.allSessionConfigs.compactMap{$0.protocolClasses}.flatMap {$0}
        AssertTrue(deinstall)
        AssertTrue(allURLProtocolClasses.contains {$0 == InstanaURLProtocol.self} == false)
    }

    func test_installingInConfiguration_shouldAddCustomProtocol() {
        // Given
        let monitor = HTTPMonitor(env, reporter: instana.monitors.reporter)
        let sessionConfig = URLSessionConfiguration.default

        // When
        monitor.install()

        // Then
        XCTAssertFalse(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? true)
        sessionConfig.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
        XCTAssertTrue(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? false)
    }
    
    func test_markingURL() {
        // Given
        let url: URL = .random
        let monitor = HTTPMonitor(env, reporter: instana.monitors.reporter)
        let size = Instana.Types.HTTPSize(header: 1, body: 2)

        // When
        let marker = try! monitor.mark(url, method: "method", size: size)

        // Then
        XCTAssertEqual(marker.url, url)
        XCTAssertEqual(marker.method, "method")
        XCTAssertEqual(marker.trigger, .automatic)
    }
    
    func test_markingRequest() {
        // Given
        let url: URL = .random
        let monitor = HTTPMonitor(env, reporter: instana.monitors.reporter)
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
        let monitor = HTTPMonitor(env, reporter: instana.monitors.reporter)
        var request = URLRequest(url: url)
        request.url = nil
        request.httpMethod = nil

        // When
        XCTAssertThrowsError(try monitor.mark(request)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.invalidRequest.rawValue)
        }
    }
    
    func test_automaticTriggerMarker_shouldBeReportedOnlyForAutomatedReporting() {
        // Given
        var config = InstanaConfiguration.default(key: "KEY")
        var count = 0

        // Automatic
        // When
        config.reportingType = .automatic
        var monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 1)

        // Automatic And manual
        // When
        config.reportingType = .automaticAndManual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 2)

        // Manual
        // When
        config.reportingType = .manual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 2)

        // None
        // When
        config.reportingType = .none
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 2)
    }
    
    func test_manualTriggerMarker_shouldBeReportedOnlyForManualReporting() {
        // Given
        var config = InstanaConfiguration.default(key: "KEY")
        var count = 0

        // Automatic
        // When
        config.reportingType = .automatic
        var monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 0)

        // Automatic And manual
        // When
        config.reportingType = .automaticAndManual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 1)

        // Manual
        // When
        config.reportingType = .manual
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 2)

        // None
        // When
        config.reportingType = .none
        monitor = HTTPMonitor(.mock(configuration: config), reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 2)
    }

    struct Random {
        static func marker(_ monitor: HTTPMonitor, trigger: HTTPMarker.Trigger) -> HTTPMarker { HTTPMarker(url: URL.random, method: "GET", trigger: trigger, delegate: monitor) }
    }
}
