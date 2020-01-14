import XCTest
@testable import InstanaAgent

class ApplicationNotRespondingMonitorTests: InstanaTestCase {

    var monitor: ApplicationNotRespondingMonitor?

    override func tearDown() {
        monitor = nil
    }
    
    func test_internalTimer_shouldNotRetainMonitor() {
        monitor = ApplicationNotRespondingMonitor(threshold: 5, reporter: MockReporter {_ in })
        weak var weakMonitor = monitor
        
        monitor = nil
        
        XCTAssertNil(weakMonitor)
    }
    
    func test_performanceOverload_triggersANRBeacon() {
        var beacon: Beacon?
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {
            beacon = $0
            exp.fulfill()
        })
        
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            guard let alert = beacon as? AlertBeacon else {
                XCTFail("Beacon not submitted or wrong type")
                return
            }
            guard case let .anr(duration) = alert.alertType else {
                XCTFail("Wrong alert type: \(alert.alertType)")
                return
            }
            XCTAssert(duration > 0.01)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerANRBeacon() {
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {_ in
            XCTFail("ANR beacon triggered in background")
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14)
    }

    func test_foregrounding_shouldResumeMonitoring() {
        var beacon: Beacon?
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {
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
