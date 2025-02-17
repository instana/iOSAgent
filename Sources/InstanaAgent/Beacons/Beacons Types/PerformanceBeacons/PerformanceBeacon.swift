//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class PerformanceBeacon: Beacon {
    enum PerformanceSubType: Equatable {
        case appLaunch
        case appNotResponding
        case lowMemory
        case framerateDrop(duration: Instana.Types.Seconds, averageFramerate: Float)
    }

    let subType: PerformanceSubType

    init(subType: PerformanceSubType) {
        self.subType = subType
        super.init()
    }
}
