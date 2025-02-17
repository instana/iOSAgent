//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class PerformanceBeacon: Beacon {
    enum PerformanceSubType: Equatable {
        case anr(duration: Instana.Types.Seconds)
        case appLaunch
        case lowMemory
        case framerateDrop(duration: Instana.Types.Seconds, averageFramerate: Float)
    }

    let subType: PerformanceSubType

    init(subType: PerformanceSubType) {
        self.subType = subType
        super.init()
    }
}
