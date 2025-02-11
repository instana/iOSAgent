import XCTest
@testable import InstanaAgent

class FramerateDropMonitorTests: InstanaTestCase {

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
    
    func x_test_framerateDrop_triggersBeacon() {
        // Given
        var beacon: Beacon?
        let exp = expectation(description: "Framerate drop beacon trigger")
        monitor = FramerateDropMonitor(threshold: 50, samplingInterval: 0.1, reporter: MockReporter {
            beacon = $0
            exp.fulfill()
        })

        // When
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        // Then
        waitForExpectations(timeout: 5) { _ in
            guard let perfBeacon = beacon as? PerformanceBeacon else {
                XCTFail("Beacon not submitted or wrong type")
                return
            }
            guard case let .framerateDrop(duration, _) = perfBeacon.subType else {
                XCTFail("Wrong performance beacon sub type: \(perfBeacon.subType)")
                return
            }
            XCTAssert(duration > 0 && duration < 1)
        }
    }
    
    func x_test_backgroundedApplication_shouldNotTriggerBeacon() {
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
    
    func x_test_foregrounding_shouldResumeMonitoring() {
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
            XCTAssertNotNil(beacon as? PerformanceBeacon)
        }
    }
}
