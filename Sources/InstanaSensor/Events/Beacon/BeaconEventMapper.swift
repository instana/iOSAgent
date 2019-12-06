//
//  File.swift
//  
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation

class BeaconEventMapper {
    private let configuration: InstanaConfiguration

    init(_ configuration: InstanaConfiguration) {
        self.configuration = configuration
    }

    func map(_ events: [Event]) throws -> [CoreBeacon] {
        return try events.map { try map($0)}
    }

    func map(_ event: Event) throws -> CoreBeacon {
        var beacon = CoreBeacon.createDefault(key: configuration.key, timestamp: event.timestamp, sessionId: event.sessionId, id: event.id)
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

extension CoreBeacon {

    mutating func append(_ event: HTTPEvent) {
        t = .httpRequest
        hu = event.url.absoluteString
        hp = event.path
        hs = String(event.responseCode)
        hm = event.method
        trs = String(event.responseSize)
        d = String(event.duration)
    }

    mutating func append(_ event: AlertEvent) {
        t = .custom // not yet defined
    }

    mutating func append(_ event: CustomEvent) {
        t = .custom
    }

    mutating func append(_ event: SessionProfileEvent) {
        if event.state == .start {
            t = .sessionStart  // there is no sessionEnd yet
        }
    }
}
