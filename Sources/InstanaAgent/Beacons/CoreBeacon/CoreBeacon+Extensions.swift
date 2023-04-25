//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

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
        if let dict = value as? [String: String] {
            return dict.asString(prefix: key)
        }
        let value = isCrashPayloadField(fieldKey: key) ? "\(value)".crashBeaconClean() : "\(value)".coreBeaconClean()
        guard !value.isEmpty else { return nil }
        return "\(key)\t\(value)"
    }
}

extension MetaData {
    func asString(prefix: String) -> String? {
        guard count > 0 else { return nil }
        return sorted { $0.0 < $1.0 }.compactMap {
            guard !$0.value.isEmpty else { return nil }
            return "\(prefix)_\($0.key)\t\($0.value.coreBeaconClean())"
        }.joined(separator: "\n")
    }
}

extension Collection where Element == CoreBeacon {
    var asString: String { compactMap { $0.asString }.joined(separator: "\n\n") }
}
