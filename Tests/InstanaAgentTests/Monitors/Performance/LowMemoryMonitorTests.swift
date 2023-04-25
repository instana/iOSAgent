import XCTest
@testable import InstanaAgent

class LowMemoryMonitorTests: InstanaTestCase {
    
    var monitor: LowMemoryMonitor?
    
    override func tearDown() {
        super.tearDown()
        monitor = nil
    }
    
    func test_deviceLowMemory_triggersLowMemoryBeacon() {
        var beacon: Beacon?
        monitor = LowMemoryMonitor(reporter: MockReporter {submittedBeacon in
            beacon = submittedBeacon
        })
        
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        let alert = beacon as? AlertBeacon
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert!.alertType, .lowMemory)
    }
}
