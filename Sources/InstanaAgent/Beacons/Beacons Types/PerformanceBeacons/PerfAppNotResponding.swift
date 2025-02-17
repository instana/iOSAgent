//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation

class PerfAppNotRespondingBeacon: PerformanceBeacon {
    let duration: Instana.Types.Seconds

    init(duration: Instana.Types.Seconds) {
        self.duration = duration
        super.init(subType: .appNotResponding)
    }
}
