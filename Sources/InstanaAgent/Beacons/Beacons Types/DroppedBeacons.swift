//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation

class DroppedBeacons: Beacon {
    let beaconsMap: [String: String]

    init(beaconsMap: [String: String],
         timestamp: Instana.Types.Milliseconds,
         viewName: String?) {
        self.beaconsMap = beaconsMap
        super.init(timestamp: timestamp, viewName: viewName)
    }
}
