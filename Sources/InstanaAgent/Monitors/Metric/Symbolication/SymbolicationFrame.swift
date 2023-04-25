//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

class SymbolicationFrame {
    let binaryUUID: UUID
    let binaryName: String
    let loadAddress: UInt
    var symbol: SymbolInfo?

    init(binaryUUID: UUID,
         binaryName: String,
         loadAddress: UInt,
         symbol: SymbolInfo? = nil) {
        self.binaryUUID = binaryUUID
        self.binaryName = binaryName
        self.loadAddress = loadAddress
        self.symbol = symbol
    }
}
