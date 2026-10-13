//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
import InstanaAgent


internal class UserEventEntry {
    var timestamp: Instana.Types.Milliseconds
    var viewClassName: String?

    init(timestamp: Instana.Types.Milliseconds, viewClassName: String? = nil) {
        self.timestamp = timestamp
        self.viewClassName = viewClassName
    }
}


internal class TouchEntry: UserEventEntry {

    internal struct TouchTrack {
        let location: CGPoint
        let timestamp: Instana.Types.Milliseconds

        func toTuple() -> [Int] {
            let x = Int(location.x)
            let y = Int(location.y)
            let timestamp = Int(timestamp)
            return [x, y, timestamp]
        }
    }

    var touches: [TouchTrack] = []
    var viewId: String?
    var isCancelled: Bool?

    init(timestamp: Instana.Types.Milliseconds, locationInWindow: CGPoint,
            viewClassName: String? = nil, viewId: String? = nil) {
        touches.append(TouchTrack(location: locationInWindow, timestamp: timestamp))
        self.viewId = viewId
        super.init(timestamp: timestamp, viewClassName: viewClassName)
    }

    func appendTouch(locationInWindow: CGPoint, timestamp: Instana.Types.Milliseconds) {
        touches.append(TouchTrack(location: locationInWindow, timestamp: timestamp))
    }

    func finish(isCancelled: Bool) {
        self.isCancelled = isCancelled
    }

    func getCoordinates() -> [[Int]] {
        let coord: [[Int]] = touches.map { track in
            return track.toTuple()
        }
        return coord
    }

    var description: String {
        return "timestamp:\(timestamp), viewType:\(viewClassName ?? "nil"), touches:\(touches)"
    }
}
