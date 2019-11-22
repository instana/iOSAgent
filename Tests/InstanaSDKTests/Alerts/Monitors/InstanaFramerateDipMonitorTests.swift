//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaFramerateDipMonitorTests: XCTestCase {

    var monitor: InstanaFramerateDipMonitor?
    
    override func tearDown() {
        monitor = nil
    }
    
    func test_internalDisplayLink_shouldNotRetainMonitor() {
        monitor = InstanaFramerateDipMonitor(threshold: 5) { _ in }
        weak var weakMonitor = monitor
        
        monitor = nil
        
        XCTAssertNil(weakMonitor)
    }
    
    func test_framerateDip_triggersEvent() {
        var event: InstanaEvent?
        let exp = expectation(description: "Framerate dip event trigger")
        monitor = InstanaFramerateDipMonitor(threshold: 50, samplingInterval: 0.1) {
            event = $0
            exp.fulfill()
        }
        
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.15) { _ in
            guard let alertEvent = event as? InstanaAlertEvent else {
                XCTFail("Event not submitted or wrong type")
                return
            }
            guard case let .framerateDip(duration, avgFPS) = alertEvent.alertType else {
                XCTFail("Wrong alert type: \(alertEvent.alertType)")
                return
            }
            XCTAssert(avgFPS <= 25)
            XCTAssert(duration > 0 && duration < 1)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerEvent() {
        let exp = expectation(description: "Framerate dip event trigger")
        monitor = InstanaFramerateDipMonitor(threshold: 50, samplingInterval: 0.01) { _ in
            XCTFail("Framerate dip event triggered in background")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.22)
    }
    
    func test_foregrounding_shouldResumeMonitoring() {
        var event: InstanaEvent?
        let exp = expectation(description: "Framerate dip event trigger")
        monitor = InstanaFramerateDipMonitor(threshold: 50, samplingInterval: 0.01) {
            event = $0
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            XCTAssertNotNil(event as? InstanaAlertEvent)
        }
    }
}
