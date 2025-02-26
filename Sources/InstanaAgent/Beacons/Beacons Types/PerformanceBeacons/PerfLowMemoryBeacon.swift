//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation

class PerfLowMemoryBeacon: PerformanceBeacon {
    let usedMemory: UInt64?
    let availableMemory: UInt64?
    let maximumMemory: UInt64?

    init(usedMemory: UInt64? = nil, availableMemory: UInt64?, maximumMemory: UInt64?) {
        self.usedMemory = usedMemory
        self.availableMemory = availableMemory
        self.maximumMemory = maximumMemory
        super.init(subType: .lowMemory)
    }
}
