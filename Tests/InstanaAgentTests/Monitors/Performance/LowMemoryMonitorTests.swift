import XCTest
@testable import InstanaAgent

class LowMemoryMonitorTests: XCTestCase {
    
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
        
        guard let alert = beacon as? AlertBeacon else {
            XCTFail("Beacon not submitted or wrong type")
            return
        }
        guard case .lowMemory = alert.alertType else {
            XCTFail("Wrong alert type: \(alert.alertType)")
            return
        }
    }
}
