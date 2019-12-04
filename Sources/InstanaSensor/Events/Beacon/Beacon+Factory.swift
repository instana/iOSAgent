//
//  Beacon+Factory+Extensions.swift
//  
//
//  Created by Christian Menschel on 02.12.19.
//

import Foundation

extension Beacon {
    static func createDefault(key: String,
                              timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
                              sessionId: String = UUID().uuidString,
                              eventId: String = UUID().uuidString) -> Beacon {
        Beacon(k: key,
               ti: String(timestamp),
               sid: sessionId,
               bid: eventId,
               buid: InstanaSystemUtils.applicationBundleIdentifier,
               ul: Locale.current.languageCode ?? "na",
               ab: InstanaSystemUtils.applicationBuildNumber,
               av: InstanaSystemUtils.applicationVersion,
               osn: InstanaSystemUtils.systemName,
               osv: InstanaSystemUtils.systemVersion,
               dmo: InstanaSystemUtils.deviceModel,
               ro: String(InstanaSystemUtils.isDeviceJailbroken),
               vw: String(Int(InstanaSystemUtils.screenSize.width)),
               vh: String(Int(InstanaSystemUtils.screenSize.height)),
               cn: InstanaSystemUtils.carrierName,
               ct: InstanaSystemUtils.connectionTypeDescription)
    }
}

extension Beacon {
    static func create(from httpBody: String) throws -> Beacon {
        let lines = httpBody.components(separatedBy: "\n")
        let kvPairs = lines.reduce([String: Any](), {result, line -> [String: Any] in
            let components = line.components(separatedBy: "\t")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            return newResult
        })
        
        let jsonData = try JSONSerialization.data(withJSONObject: kvPairs, options: .prettyPrinted)
        let beacon = try JSONDecoder().decode(Beacon.self, from: jsonData)
        return beacon
    }

    var asString: String? {
        guard let jsonData = try? JSONEncoder().encode(self),
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed) as? [String: Any] else {
                return nil
        }
        let pairs = json.sorted { $0.0 < $1.0 }.compactMap { (key, value) in
            return formattedKVPair(key: key, value: value)
        }
        return pairs.joined(separator: "\n")
    }
}

extension Beacon {

    func formattedKVPair(key: String, value: Any) -> String? {
        guard let value = cleaning(value) else { return nil }
        return "\(key)\t\(value)"
    }

    func cleaning<T: Any>(_ entry: T) -> T? {
        if let stringValue = entry as? String {
            var trimmed = stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            trimmed = trimmed.truncated(at: Int(Beacon.maxBytesPerField))
            trimmed = trimmed.replacingOccurrences(of: "\t", with: "")
            return trimmed.isEmpty ? nil : trimmed as? T
        }
        return entry
    }
}

extension Collection where Element == Beacon {
    var asString: String { compactMap {$0.asString}.joined(separator: "\n\n") }
}
