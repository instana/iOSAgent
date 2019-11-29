//  Created by Nikola Lajic on 3/18/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class HTTPMonitorTests: XCTestCase {

    func test_installing_shouldAddCustomProtocol() {
        var installed = false
        let rci = HTTPMonitor(installer: {
            XCTAssert($0 == InstanaURLProtocol.self)
            installed = true
            return true
        })
        rci.install()
        XCTAssertTrue(installed)
    }
    
    func test_uninstalling_shouldRemoveCustomProtocol() {
        var uninstalled = false
        let rci = HTTPMonitor(uninstaller: {
            XCTAssert($0 == InstanaURLProtocol.self)
            uninstalled = true
        })
        rci.uninstall()
        XCTAssertTrue(uninstalled)
    }
    
    func test_changingReportingType_shouldInstallAndUnistallCustomProtocoll() {
        var installed: [HTTPMonitor.ReportingType?] = []
        var uninstalled: [HTTPMonitor.ReportingType?] = []
        var rci: HTTPMonitor?
        rci = HTTPMonitor(installer: { _ in
            installed.append(rci?.reporting); return true
        }, uninstaller: { _ in
            uninstalled.append(rci?.reporting)
        })
        
        rci?.reporting = .automaticAndManual
        rci?.reporting = .automatic
        rci?.reporting = .manual
        rci?.reporting = .none
        
        let expectedInstalled: [HTTPMonitor.ReportingType?] = [.automaticAndManual, .automatic]
        XCTAssertEqual(installed,  expectedInstalled)
        let expectedUninstalled: [HTTPMonitor.ReportingType?] = [.manual, HTTPMonitor.ReportingType.none]
        XCTAssertEqual(uninstalled, expectedUninstalled)
    }
    
    func test_installingInConfiguration_shouldAddCustomProtocol() {
        let rci = HTTPMonitor()
        let config = URLSessionConfiguration.default
        XCTAssertFalse(config.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? true)
        rci.install(in: config)
        XCTAssertTrue(config.protocolClasses?.contains { $0 == InstanaURLProtocol.self } ?? false)
    }
    
    func test_markingCall_shouldReturnPreparedMarker() {
        let rci = HTTPMonitor(networkConnectionType: { .wifi })
        let marker = rci.markCall(to: "www.test.url", method: "method")
        XCTAssertEqual(marker.url, "www.test.url")
        XCTAssertEqual(marker.method, "method")
        XCTAssertEqual(marker.trigger, .manual)
        XCTAssertEqual(marker.connectionType, .wifi)
    }
    
    func test_markingRequest_shouldReturnSetUpMarker() {
        let rci = HTTPMonitor(networkConnectionType: { .cellular })
        var request = URLRequest(url: URL(string: "www.a.com")!)
        request.httpMethod = "m"
        request.httpBody = "11".data(using: .utf8)
        let marker = rci.markCall(for: request)
        XCTAssertEqual(marker.url, "www.a.com")
        XCTAssertEqual(marker.method, "m")
        XCTAssertEqual(marker.requestSize, 2)
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertEqual(marker.connectionType, .cellular)
    }
    
    func test_markingRequestWithDefaultValues_shouldReturnPreparedMarker() {
        let rci = HTTPMonitor(networkConnectionType: { nil })
        var request = URLRequest(url: URL(string: "a")!)
        request.url = nil
        request.httpMethod = nil
        let marker = rci.markCall(for: request)
        XCTAssertEqual(marker.url, "")
        XCTAssertEqual(marker.method, "GET")
        XCTAssertEqual(marker.requestSize, 0)
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertNil(marker.connectionType)
    }
    
    func test_automaticTriggerMarker_shouldBeReportedOnlyForAutomatedReporting() {
        var count = 0
        let rci = HTTPMonitor(submitter: { _ in
            count += 1
        })
        let marker = HTTPMarker(url: "", method: "", trigger: .automatic, delegate: rci)
        
        rci.reporting = .automatic
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 1)
        
        rci.reporting = .automaticAndManual
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 2)
        
        rci.reporting = .manual
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 2)
        
        rci.reporting = .none
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 2)
    }
    
    func test_manualTriggerMarker_shouldBeReportedOnlyForManualReporting() {
        var count = 0
        let rci = HTTPMonitor(submitter: { _ in
            count += 1
        })
        let marker = HTTPMarker(url: "", method: "", trigger: .manual, delegate: rci)
        
        rci.reporting = .automatic
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 0)
        
        rci.reporting = .automaticAndManual
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 1)
        
        rci.reporting = .manual
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 2)
        
        rci.reporting = .none
        rci.finalized(marker: marker)
        XCTAssertEqual(count, 2)
    }
}
