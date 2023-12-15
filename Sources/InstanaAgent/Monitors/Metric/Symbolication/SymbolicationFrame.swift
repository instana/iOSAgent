//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

class SymbolicationFrame {
    let binaryUUID: UUID
    let binaryName: String
    let offsetIntoBinaryTextSegment: UInt
    var sampleCount: Int?
    var symbol: SymbolInfo?

    init(binaryUUID: UUID,
         binaryName: String,
         offsetIntoBinaryTextSegment: UInt,
         symbol: SymbolInfo? = nil) {
        self.binaryUUID = binaryUUID
        self.binaryName = binaryName
        self.offsetIntoBinaryTextSegment = offsetIntoBinaryTextSegment
        self.symbol = symbol
    }
}
