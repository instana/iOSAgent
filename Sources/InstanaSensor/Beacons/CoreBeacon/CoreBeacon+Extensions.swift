//
//  Beacon+Factory+Extensions.swift
//  
//
//  Created by Christian Menschel on 02.12.19.
//

import Foundation

extension CoreBeacon {
    var asString: String? {
        guard let json = asJSON else { return nil }
        let pairs = json.sorted { $0.0 < $1.0 }.compactMap { (key, value) in
            return formattedKVPair(key: key, value: value)
        }
        return pairs.joined(separator: "\n")
    }

    var asJSON: [String: Any]? {
        guard let jsonData = try? JSONEncoder().encode(self),
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed) as? [String: Any] else {
                return nil
        }
        return json
    }

    func formattedKVPair(key: String, value: Any) -> String? {
        let value = cleaning(value)
        guard Mirror.isNotNil(value: value) else { return nil }
        return "\(key)\t\(value)"
    }

    func cleaning<T: Any>(_ entry: T) -> T {
        if let stringValue = entry as? String {
            var trimmed = stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            trimmed = trimmed.truncated(at: Int(CoreBeacon.maxBytesPerField))
            trimmed = trimmed.replacingOccurrences(of: "\t", with: "")
            return trimmed as! T
        }
        return entry
    }
}

extension Collection where Element == CoreBeacon {
    var asString: String { compactMap {$0.asString}.joined(separator: "\n\n") }
}
