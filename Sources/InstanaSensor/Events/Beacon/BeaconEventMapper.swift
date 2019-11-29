//
//  File.swift
//  
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation

class BeaconEventMapper {
    let key: String

    init(key: String) {
        self.key = key
    }

    func map(_ events: [Event]) throws -> [Beacon] {
        return try events.map { try map($0)}
    }

    func map(_ event: Event) throws -> Beacon {
        var beacon = Beacon.createDefault(key: key, timestamp: event.timestamp, sessionId: event.sessionId, eventId: event.eventId)
        switch event {
        case let e as HTTPEvent:
            beacon.append(e)
        case let e as AlertEvent:
            beacon.append(e)
        case let e as CustomEvent:
            beacon.append(e)
        case let e as SessionProfileEvent:
            beacon.append(e)
        default:
            let message = "Event <-> Beacon mapping for event \(event) not defined"
            debugAssertFailure(message)
            throw InstanaError(code: .unknownType, description: message)
        }
        return beacon
    }
}

extension Beacon {

    mutating func append(_ event: HTTPEvent) {
        t = .httpRequest
        hu = event.url
        hp = event.path
        hs = event.responseCode
        hm = event.method
        trs = event.responseSize
        d = event.duration
    }

    mutating func append(_ event: AlertEvent) {
        t = .custom // not yet defined
    }

    mutating func append(_ event: CustomEvent) {
        t = .custom
    }

    mutating func append(_ event: SessionProfileEvent) {
        if event.state == .start {
            t = .sessionStart  // there is no such end yet
        }
    }
}

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
