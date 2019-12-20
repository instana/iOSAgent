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
    
    func test_framerateDrop_triggersBeacon() {
        var beacon: Beacon?
        let exp = expectation(description: "Framerate drop beacon trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.1, reporter: MockReporter {
            beacon = $0
            exp.fulfill()
        })
        
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.25) { _ in
            guard let alert = beacon as? AlertBeacon else {
                XCTFail("Beacon not submitted or wrong type")
                return
            }
            guard case let .framerateDrop(duration, avgFPS) = alert.alertType else {
                XCTFail("Wrong alert type: \(alert.alertType)")
                return
            }
            XCTAssert(avgFPS <= 25)
            XCTAssert(duration > 0 && duration < 1)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerBeacon() {
        let exp = expectation(description: "Framerate drop beacon trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.01, reporter: MockReporter {_ in
            XCTFail("Framerate drop beacon triggered in background")
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.1)
        
        waitForExpectations(timeout: 0.22)
    }
    
    func test_foregrounding_shouldResumeMonitoring() {
        var beacon: Beacon?
        let exp = expectation(description: "Framerate drop beacon trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.01, reporter: MockReporter {
            beacon = $0
            exp.fulfill()
        })
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            XCTAssertNotNil(beacon as? AlertBeacon)
        }
    }
}
