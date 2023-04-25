//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

extension Set {
    func chunkedBeacons(size: Int) -> [[Element]] {
        var beacons = [[Element]]()
        var oneBatch = [Element]()
        oneBatch.reserveCapacity(size)
        forEach {
            if let bcn = $0 as? CoreBeacon {
                if oneBatch.count == size {
                    beacons.append(oneBatch)
                    oneBatch.removeAll(keepingCapacity: true)
                }
                if bcn.t == .crash {
                    beacons.append([$0])
                } else {
                    oneBatch.append($0)
                }
            }
        }
        if oneBatch.count > 0 {
            beacons.append(oneBatch)
        }
        return beacons
    }
}
