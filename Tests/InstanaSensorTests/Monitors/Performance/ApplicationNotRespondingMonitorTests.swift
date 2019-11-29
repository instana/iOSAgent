//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class ApplicationNotRespondingMonitorTests: XCTestCase {

    var monitor: ApplicationNotRespondingMonitor?
    
    override func tearDown() {
        monitor = nil
    }
    
    func test_internalTimer_shouldNotRetainMonitor() {
        monitor = ApplicationNotRespondingMonitor(threshold: 5) { _ in }
        weak var weakMonitor = monitor
        
        monitor = nil
        
        XCTAssertNil(weakMonitor)
    }
    
    func test_performanceOverload_triggersANREvent() {
        var event: Event?
        let exp = expectation(description: "ANR event trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1) {
            event = $0
            exp.fulfill()
        }
        
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            guard let alertEvent = event as? AlertEvent else {
                XCTFail("Event not submitted or wrong type")
                return
            }
            guard case let .anr(duration) = alertEvent.alertType else {
                XCTFail("Wrong alert type: \(alertEvent.alertType)")
                return
            }
            XCTAssert(duration > 0.01)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerANREvent() {
        let exp = expectation(description: "ANR event trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1) { _ in
            XCTFail("ANR event triggered in background")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14)
    }
    
    func test_foregrounding_shouldResumeMonitoring() {
        var event: Event?
        var count = 0
        let exp = expectation(description: "ANR event trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1) {
            event = $0
            count += 1
        }
        // fulfill expectation after a timer to catch mutliple events
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            XCTAssertNotNil(event as? AlertEvent)
            XCTAssertEqual(count, 1)
        }
    }
}
