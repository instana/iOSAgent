//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class FramerateDropMonitorTests: XCTestCase {

    var monitor: FramerateDropMonitor?
    
    override func tearDown() {
        monitor = nil
    }
    
    func test_internalDisplayLink_shouldNotRetainMonitor() {
        monitor = FramerateDropMonitor(threshold: 5, reporter: MockReporter {_ in})
        weak var weakMonitor = monitor
        
        monitor = nil
        
        XCTAssertNil(weakMonitor)
    }
    
    func test_framerateDrop_triggersEvent() {
        var event: Event?
        let exp = expectation(description: "Framerate drop event trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.1, reporter: MockReporter {
            event = $0
            exp.fulfill()
        })
        
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.15) { _ in
            guard let alertEvent = event as? AlertEvent else {
                XCTFail("Event not submitted or wrong type")
                return
            }
            guard case let .framerateDrop(duration, avgFPS) = alertEvent.alertType else {
                XCTFail("Wrong alert type: \(alertEvent.alertType)")
                return
            }
            XCTAssert(avgFPS <= 25)
            XCTAssert(duration > 0 && duration < 1)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerEvent() {
        let exp = expectation(description: "Framerate drop event trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.01, reporter: MockReporter {_ in
            XCTFail("Framerate drop event triggered in background")
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.22)
    }
    
    func test_foregrounding_shouldResumeMonitoring() {
        var event: Event?
        let exp = expectation(description: "Framerate drop event trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.01, reporter: MockReporter {
            event = $0
            exp.fulfill()
        })
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            XCTAssertNotNil(event as? AlertEvent)
        }
    }
}
