import XCTest
@testable import InstanaAgent

class AppLaunchMonitorTests: InstanaTestCase {
    var monitor: AppLaunchMonitor?
    var reporterRetainer: [Reporter]!

    override func setUp() {
        super.setUp()
        // Need to retain the reporter otherwise the lifetime is not guranteed with all delays
        reporterRetainer = [Reporter]()
    }

    override func tearDown() {
        monitor = nil
        reporterRetainer = nil
        super.tearDown()
    }
    
    func test_appLaunchColdStartTest() {
        var beacon: Beacon?
        let reporter = MockReporter { submittedBeacon in
            beacon = submittedBeacon
        }
        reporterRetainer.append(reporter)
        monitor = AppLaunchMonitor(reporter: reporter)

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        let perfBeacon = beacon as? PerfAppLaunchBeacon
        XCTAssertNotNil(perfBeacon)
        XCTAssertEqual(perfBeacon!.subType, .appLaunch)
        XCTAssertNotNil(perfBeacon!.appColdStartTime)
        XCTAssertNil(perfBeacon!.appWarmStartTime)
        XCTAssertNil(perfBeacon!.appHotStartTime)
    }

    func test_appLaunchWarmStartTest() {
        var beacon: Beacon?
        let reporter = MockReporter { submittedBeacon in
            beacon = submittedBeacon
        }
        reporterRetainer.append(reporter)
        monitor = AppLaunchMonitor(reporter: reporter)

        monitor?.prewarm = nil
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        let perfBeacon = beacon as? PerfAppLaunchBeacon
        XCTAssertNotNil(perfBeacon)
        XCTAssertEqual(perfBeacon!.subType, .appLaunch)
        XCTAssertNil(perfBeacon!.appColdStartTime)
        XCTAssertNotNil(perfBeacon!.appWarmStartTime)
        XCTAssertNil(perfBeacon!.appHotStartTime)
    }

    func test_appLaunchHotStartTest() {
        var beacon: Beacon?
        let reporter = MockReporter { submittedBeacon in
            beacon = submittedBeacon
        }
        reporterRetainer.append(reporter)
        monitor = AppLaunchMonitor(reporter: reporter)

        monitor?.prewarm = nil
        monitor?.hotStartBeginTime = CFAbsoluteTimeGetCurrent() - 0.1
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        let perfBeacon = beacon as? PerfAppLaunchBeacon
        XCTAssertNotNil(perfBeacon)
        XCTAssertEqual(perfBeacon!.subType, .appLaunch)
        XCTAssertNil(perfBeacon!.appColdStartTime)
        XCTAssertNil(perfBeacon!.appWarmStartTime)
        XCTAssertNotNil(perfBeacon!.appHotStartTime)
    }
}
