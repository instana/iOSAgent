//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class LowMemoryMonitorTests: XCTestCase {
    
    var monitor: LowMemoryMonitor?
    
    override func tearDown() {
        super.tearDown()
        monitor = nil
    }
    
    func test_deviceLowMemory_triggersLowMemoryEvent() {
        var event: Event?
        monitor = LowMemoryMonitor(reporter: MockReporter {submittedEvent in
            event = submittedEvent
        })
        
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        guard let alertEvent = event as? AlertEvent else {
            XCTFail("Event not submitted or wrong type")
            return
        }
        guard case .lowMemory = alertEvent.alertType else {
            XCTFail("Wrong alert type: \(alertEvent.alertType)")
            return
        }
    }
}
