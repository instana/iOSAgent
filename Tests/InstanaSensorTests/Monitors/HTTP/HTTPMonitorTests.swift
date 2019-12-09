//  Created by Nikola Lajic on 3/18/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class HTTPMonitorTests: XCTestCase {

    var config: InstanaConfiguration!
    var instana: Instana!

    override func setUp() {
        super.setUp()
        Instana.setup(key: "KEY123")
        instana = Instana.current
        config = instana.configuration
    }

    override func tearDown() {
        super.tearDown()
        self.instana = nil
    }

    func test_installing_shouldAddCustomProtocol() {
        var installed = false
        let monitor = HTTPMonitor(config, installer: {
            XCTAssert($0 == InstanaURLProtocol.self)
            installed = true
            return true
        }, reporter: instana.monitors.reporter)
        monitor.install()
        XCTAssertTrue(installed)
    }
    
    func test_uninstalling_shouldRemoveCustomProtocol() {
        var uninstalled = false
        let monitor = HTTPMonitor(config, uninstaller: {
            XCTAssert($0 == InstanaURLProtocol.self)
            uninstalled = true
        }, reporter: instana.monitors.reporter)
        monitor.uninstall()
        XCTAssertTrue(uninstalled)
    }

    func test_installingInConfiguration_shouldAddCustomProtocol() {
        // Given
        let monitor = HTTPMonitor(config, reporter: instana.monitors.reporter)
        let sessionConfig = URLSessionConfiguration.default

        // Then
        XCTAssertFalse(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? true)
        monitor.track(sessionConfig)
        XCTAssertTrue(sessionConfig.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? false)
    }
    
    func test_markingURL() {
        // Given
        let url: URL = .random
        let monitor = HTTPMonitor(config, reporter: instana.monitors.reporter)
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
        let monitor = HTTPMonitor(config, reporter: instana.monitors.reporter)
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
        let monitor = HTTPMonitor(config, reporter: instana.monitors.reporter)
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
        var monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 1)

        // Automatic And manual
        // When
        config.reportingType = .automaticAndManual
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 2)

        // Manual
        // When
        config.reportingType = .manual
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .automatic))
        // Then
        XCTAssertEqual(count, 2)

        // None
        // When
        config.reportingType = .none
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
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
        var monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 0)

        // Automatic And manual
        // When
        config.reportingType = .automaticAndManual
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 1)

        // Manual
        // When
        config.reportingType = .manual
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
            count += 1
        })
        monitor.finalized(marker: Random.marker(monitor, trigger: .manual))
        // Then
        XCTAssertEqual(count, 2)

        // None
        // When
        config.reportingType = .none
        monitor = HTTPMonitor(config, reporter: MockReporter { _ in
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
