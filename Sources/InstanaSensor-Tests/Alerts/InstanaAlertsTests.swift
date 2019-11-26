//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaAlertsTests: XCTestCase {

    func test_defaultMonitors_shouldBeNil() {
        let alerts = InstanaAlerts()
        let mirror = Mirror(reflecting: alerts)
        XCTAssertNil(mirror.typedChild(at: "applicationNotRespondingMonitor", type: ApplicationNotRespondingMonitor.self))
        XCTAssertNil(mirror.typedChild(at: "lowMemoryMonitor", type: LowMemoryMonitor.self))
        XCTAssertNil(mirror.typedChild(at: "framerateDropMonitor", type: FramerateDropMonitor.self))
    }
    
    func test_settingFramerateThreshold_initializesMonitor() {
        let alerts = InstanaAlerts()
        let mirror = Mirror(reflecting: alerts)
        let typedChild: () -> Any? = { mirror.typedChild(at: "framerateDropMonitor", type: FramerateDropMonitor.self) }
        
        XCTAssertNil(typedChild())
        alerts.framerateDropThreshold = 10
        XCTAssertNotNil(typedChild())
        alerts.framerateDropThreshold = nil
        XCTAssertNil(typedChild())
    }
    
    func test_settingLowMemory_initializesMonitor() {
        let alerts = InstanaAlerts()
        let mirror = Mirror(reflecting: alerts)
        let typedChild: () -> Any? = { mirror.typedChild(at: "lowMemoryMonitor", type: LowMemoryMonitor.self) }
        
        XCTAssertNil(typedChild())
        alerts.lowMemory = true
        XCTAssertNotNil(typedChild())
        alerts.lowMemory = false
        XCTAssertNil(typedChild())
    }
    
    func test_settingANRThreshold_initializesMonitor() {
        let alerts = InstanaAlerts()
        let mirror = Mirror(reflecting: alerts)
        let typedChild: () -> ApplicationNotRespondingMonitor? = { mirror.typedChild(at: "applicationNotRespondingMonitor", type: ApplicationNotRespondingMonitor.self) }
        
        XCTAssertNil(typedChild())
        
        alerts.applicationNotRespondinThreshold = 0.1
        let firstMonitor = typedChild()
        XCTAssertNotNil(firstMonitor)
        XCTAssertEqual(firstMonitor?.threshold, 0.1)
        alerts.applicationNotRespondinThreshold = 0.2
        XCTAssertEqual(firstMonitor?.threshold, 0.2)
        
        alerts.applicationNotRespondinThreshold = nil
        XCTAssertNil(typedChild())
    }
}


