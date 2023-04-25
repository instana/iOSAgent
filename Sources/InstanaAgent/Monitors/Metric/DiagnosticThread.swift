//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

class DiagnosticThread: Codable {
    let threadAttributed: Bool?
    let callStackRootFrames: [Frame]
    var formatted: [SymbolicationFrame?]?

    private enum CodingKeys: String, CodingKey {
        case threadAttributed
        case callStackRootFrames
    }

    var frameArray: [Frame] {
        return callStackRootFrames.flatMap { [$0] + $0.frameArray }
    }
}
