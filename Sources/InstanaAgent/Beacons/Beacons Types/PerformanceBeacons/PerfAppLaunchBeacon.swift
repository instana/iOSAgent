//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation

class PerfAppLaunchBeacon: PerformanceBeacon {
    // in milliseconds
    let appColdStartTime: Int?
    let appWarmStartTime: Int?
    let appHotStartTime: Int?

    init(appColdStartTime: Int? = nil,
         appWarmStartTime: Int? = nil,
         appHotStartTime: Int? = nil) {
        self.appColdStartTime = appColdStartTime
        self.appWarmStartTime = appWarmStartTime
        self.appHotStartTime = appHotStartTime
        super.init(subType: .appLaunch)
    }
}
