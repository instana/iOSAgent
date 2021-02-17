//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

extension String {
    func coreBeaconClean() -> String {
        cleanEscapeAndTruncate(at: CoreBeacon.maxLengthPerField)
    }

    func cleanEscapeAndTruncate(at length: Int, trailing: String = "…") -> String {
        return cleanEscape().maxLength(length, trailing: trailing)
    }

    func cleanEscape() -> String {
        var trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        trimmed = trimmed.replacingOccurrences(of: "\\", with: "\\\\")
        trimmed = trimmed.replacingOccurrences(of: "\n", with: "\\n")
        trimmed = trimmed.replacingOccurrences(of: "\t", with: "\\t")
        return trimmed
    }

    func maxLength(_ length: Int, trailing: String = "…") -> String {
        if count <= length {
            return self
        }
        return String(prefix(length - trailing.count)) + trailing
    }
}
