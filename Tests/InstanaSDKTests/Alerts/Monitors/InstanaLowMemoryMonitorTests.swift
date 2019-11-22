//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaLowMemoryMonitorTests: XCTestCase {
    
    var monitor: InstanaLowMemoryMonitor?
    
    override func tearDown() {
        super.tearDown()
        monitor = nil
    }
    
    func test_deviceLowMemory_triggersLowMemoryEvent() {
        var event: InstanaEvent?
        monitor = InstanaLowMemoryMonitor { event = $0 }
        
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        guard let alertEvent = event as? InstanaAlertEvent else {
            XCTFail("Event not submitted or wrong type")
            return
        }
        guard case .lowMemory = alertEvent.alertType else {
            XCTFail("Wrong alert type: \(alertEvent.alertType)")
            return
        }
    }
}
