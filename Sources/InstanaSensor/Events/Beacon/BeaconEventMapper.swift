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
