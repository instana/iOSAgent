//
//  File.swift
//  
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation

class BeaconMapper {
    let key: String

    init(key: String) {
        self.key = key
    }

    func single(from event: Event) throws -> Beacon {
        var beacon = Beacon.createDefault(event, key: key)
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
            assertionFailure(message)
            throw InstanaError(code: .unknownType, description: message)
        }
        return beacon
    }

    func multiple(from events: [Event]) throws -> [Beacon] {
        return try events.map { try single(from: $0)}
    }
}
