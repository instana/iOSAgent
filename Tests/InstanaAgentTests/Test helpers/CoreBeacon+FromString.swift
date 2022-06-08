import Foundation
@testable import InstanaAgent

extension CoreBeacon {
    static func create(from httpBody: String) throws -> CoreBeacon {
        var dictPairs = [String: [String: String]]()
        let lines = httpBody.components(separatedBy: "\n")
        var kvPairs = lines.reduce([String: Any]()) { result, line -> [String: Any] in
            let components = line.components(separatedBy: "\t")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            if key.contains("_") {
                let comps = key.components(separatedBy: "_")
                let rootKey = comps.first!
                let newKey = comps[1...].joined(separator: "_")
                var pair = dictPairs[rootKey] ?? [String: String]()
                pair[newKey] = value
                dictPairs[rootKey] = pair
            }
            return newResult
        }
        dictPairs.forEach { key, value in
            kvPairs[key] = value
        }
        let jsonData = try JSONSerialization.data(withJSONObject: kvPairs, options: .prettyPrinted)
        let beacon = try JSONDecoder().decode(CoreBeacon.self, from: jsonData)
        return beacon
    }
}
