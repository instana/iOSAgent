//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

struct SymbolInfo: Codable, Hashable {
    public var symbol: String
    public var offset: Int?
    public var demangledSymbol: String?
}
