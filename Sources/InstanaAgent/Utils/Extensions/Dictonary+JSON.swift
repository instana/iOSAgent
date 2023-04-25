//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

extension Dictionary {
    func asJsonStr() -> String? {
        var jsonStr: String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .sortedKeys)
            jsonStr = String(decoding: jsonData, as: UTF8.self)
        } catch {
            return nil
        }
        return jsonStr
    }
}
