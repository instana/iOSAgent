//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

struct Frame: Codable {
    let binaryUUID: UUID?
    let offsetIntoBinaryTextSegment: Int?
    let sampleCount: Int?
    let subFrames: [Frame]?
    let binaryName: String?
    let address: UInt?

    public var frameArray: [Frame] {
        return subFrames?.flatMap { [$0] + $0.frameArray } ?? []
    }

    func symbolicationFrame() -> SymbolicationFrame? {
        guard
            let offset = offsetIntoBinaryTextSegment,
            let binaryName = binaryName,
            let uuid = binaryUUID else { return nil }

        return SymbolicationFrame(binaryUUID: uuid, binaryName: binaryName, offsetIntoBinaryTextSegment: UInt(offset), symbol: nil)
    }
}
