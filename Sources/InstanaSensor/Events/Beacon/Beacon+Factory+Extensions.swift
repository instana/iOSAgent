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
        ti: timestamp,
        sid: sessionId,
        bid: eventId,
        buid: InstanaSystemUtils.applicationBundleIdentifier,
        lg: Locale.current.languageCode ?? "na",
        ab: InstanaSystemUtils.applicationBuildNumber,
        av: InstanaSystemUtils.applicationVersion,
        osn: InstanaSystemUtils.systemName,
        osv: InstanaSystemUtils.systemVersion,
        dmo: InstanaSystemUtils.deviceModel,
        ro: InstanaSystemUtils.isDeviceJailbroken,
        vw: Int(InstanaSystemUtils.screenSize.width),
        vh: Int(InstanaSystemUtils.screenSize.height),
        cn: InstanaSystemUtils.carrierName,
        ct: InstanaSystemUtils.connectionTypeDescription)
    }
}

extension Beacon {
    static func create(from httpBody: String) -> Beacon {
        let lines = httpBody.components(separatedBy: "\n")
        let kvPairs = lines.reduce([String: String](), {result, line -> [String: String] in
            var result = result
            let components = line.components(separatedBy: "\t")
            if let key = components.first, let value = components.last {
                result[key] = value
            }
            return result
        })

        var beacon = Beacon.createDefault(key: kvPairs["k"] ?? "")
        let mirror = Mirror(reflecting: beacon)
        mirror.children.forEach { child in
            if let key = child.label, let value = kvPairs[key] {
                // TODO: use dynamic member lookup here and make all fields in Beacon type string
            }
        }
        return beacon
    }
}

extension Beacon {

    var keyValuePairs: String {
        let mirror = Mirror(reflecting: self)
        let pairs = mirror.nonNilChildren.compactMap { formattedKVPair(key: $0.label, value: $0.value)}
        return pairs.joined(separator: "\n")
    }

    func formattedKVPair(key: String, value: Any) -> String? {
        guard let value = cleaning(value) else { return nil }
        return "\(key)\t\(value)"
    }

    func cleaning<T: Any>(_ entry: T) -> T? {
        if let stringValue = entry as? String {
            var trimmed = stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            trimmed = trimmed.replacingOccurrences(of: "\t", with: "")
            return trimmed.isEmpty ? nil : trimmed as? T
        }
        return entry
    }
}

extension Collection where Element == Beacon {
    var plainKeyValuePairs: [String] { map {$0.keyValuePairs} }
}
