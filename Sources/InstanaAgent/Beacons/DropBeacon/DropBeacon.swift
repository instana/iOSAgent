//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation

///
/// Base class for dropped beacon
///
///
public class DropBeacon {
    var count: Int
    var timeMin: Instana.Types.Milliseconds
    var timeMax: Instana.Types.Milliseconds

    init(timestamp: Instana.Types.Milliseconds) {
        count = 1
        timeMin = timestamp
        timeMax = timestamp
    }

    func getKey() -> String {
        return "dropBeaconPlaceholderKey"
    }

    func toString() -> String? {
        return nil
    }

    func dictionaryToJsonString(_ dict: [String: Any]?, needSort: Bool = true) -> String? {
        guard let dict = dict else {
            return nil
        }
        do {
            let options: JSONSerialization.WritingOptions = needSort ? [.sortedKeys] : []
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: options)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return validateLength(jsonString)
            }
        } catch {
            Instana.current?.session.logger.add("Error converting dictionary to JSON: \(error.localizedDescription)")
        }
        return nil
    }

    func convertToString(type: String, subDict: [String: Any]) -> String? {
        let zInfoBase = ["tMin": timeMin, "tMax": timeMax]
        let zInfoDict = subDict.reduce(into: zInfoBase) { result, element in
            result[element.key] = element.value
        }
        let dict = ["type": type, "count": count, "zInfo": zInfoDict] as [String: Any]
        return dictionaryToJsonString(dict)
    }

    public func validateLength(_ str: String, maxLen: Int = 1024) -> String {
        if str.count <= maxLen {
            return str
        }
        return str.prefix(maxLen - 3) + "..."
    }
}
