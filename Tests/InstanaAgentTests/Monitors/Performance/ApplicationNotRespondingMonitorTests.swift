import XCTest
@testable import InstanaAgent

class ApplicationNotRespondingMonitorTests: InstanaTestCase {

    var monitor: ApplicationNotRespondingMonitor?
    var reporterRetainer: [Reporter]!

    override func setUp() {
        super.setUp()
        reporterRetainer = [Reporter]()
    }

    override func tearDown() {
        monitor = nil
        reporterRetainer = nil
        super.tearDown()
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
        let reporter = MockReporter {
            beacon = $0
            exp.fulfill()
        }
        reporterRetainer.append(reporter)
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: reporter)

        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            guard let perfBeacon = beacon as? PerfAppNotRespondingBeacon else {
                XCTFail("Beacon not submitted or wrong type")
                return
            }
            if perfBeacon.subType != .appNotResponding {
                XCTFail("Wrong performance beacon sub type: \(perfBeacon.subType)")
                return
            }
            XCTAssert(perfBeacon.duration > 0.01)
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
        
        waitForExpectations(timeout: 5.0)
    }

    func test_foregrounding_shouldResumeMonitoring() {
        var beacon: Beacon?
        let exp = expectation(description: "ANR beacon trigger")
        let reporter = MockReporter {
            beacon = $0
            exp.fulfill()
        }
        reporterRetainer.append(reporter)
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 2.0, reporter: reporter)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)

        waitForExpectations(timeout: 0.14) { _ in
            let perfBeacon = beacon as? PerfAppNotRespondingBeacon
            XCTAssertNotNil(perfBeacon)
            XCTAssertTrue(perfBeacon!.duration >= 0.01)

        }
    }
}
