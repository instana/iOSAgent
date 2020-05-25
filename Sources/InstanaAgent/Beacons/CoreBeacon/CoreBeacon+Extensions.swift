import Foundation

extension CoreBeacon {
    var asString: String? {
        guard let json = asJSON else { return nil }
        let pairs = json.sorted { $0.0 < $1.0 }.compactMap { key, value in
            formattedKVPair(key: key, value: value)
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
        guard Mirror.isNotNil(value: value) else { return nil }
        if let dict = value as? [AnyHashable: AnyObject] {
            return dict.asString(prefix: key)
        }
        let value = "\(value)".cleanAndEscape()
        return "\(key)\t\(value)"
    }
}

extension Dictionary {
    func asString(prefix: String) -> String {
        return map {
            let value = "\($0.value)".cleanAndEscape()
            return "\(prefix)_\($0.key)\t\(value)"
        }.joined(separator: "\n")
    }
}

extension String {
    func cleanAndEscape() -> Self {
        var trimmed = trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        trimmed = trimmed.truncated(at: Int(CoreBeacon.maxBytesPerField))
        trimmed = trimmed.replacingOccurrences(of: "\\", with: "\\\\")
        trimmed = trimmed.replacingOccurrences(of: "\n", with: "\\n")
        trimmed = trimmed.replacingOccurrences(of: "\t", with: "\\t")
        return trimmed
    }
}

extension Collection where Element == CoreBeacon {
    var asString: String { compactMap { $0.asString }.joined(separator: "\n\n") }
}
