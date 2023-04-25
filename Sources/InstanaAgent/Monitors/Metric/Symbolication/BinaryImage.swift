//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

struct BinaryImage {
    var loadAddress: UInt
    var binaryName: String
    var binaryUUID: String
    var maxAddress: UInt
    var arch: String
    var fullPath: String

    init(loadAddress: UInt,
         binaryName: String,
         binaryUUID: String) {
        self.loadAddress = loadAddress
        self.binaryName = binaryName
        self.binaryUUID = binaryUUID
        maxAddress = 0
        arch = "<unknown>"
        fullPath = ""
    }
}
