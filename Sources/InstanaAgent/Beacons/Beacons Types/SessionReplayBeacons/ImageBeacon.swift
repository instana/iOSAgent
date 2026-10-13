//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

@_spi(Internal)
public struct ImageBeacon: Codable {
    public var img: Data? // image data
    public let meta: [String: String]
    public let ti: Instana.Types.Milliseconds // timestamp in ms when the beacon is created
    var rct: Int? // retry count

    public init(image: Data?, meta: [String: String],
                timestamp: Instana.Types.Milliseconds, retryCount: Int? = nil) {
        img = image
        self.meta = meta
        ti = timestamp
        rct = retryCount
    }

    mutating func increaseRetryCount() {
        if rct == nil {
            rct = 1
        } else {
            rct! += 1
        }
    }

    /**
     * In-flight flag
     *
     * Marks beacon as currently being sent to prevent duplicate sends.
     * Gets cleared on successful send or when device conditions prevent sending.
     *
     * Example: true
     */
    var ifl: Bool?

    mutating func markInFlight() {
        ifl = true
    }

    mutating func clearInFlight() {
        ifl = nil
    }
}

extension ImageBeacon: RestartRecoverableInFlight {}

extension ImageBeacon: Hashable {
    // timestamp is practically unique because the frequency screenshot taken is low
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ti)
    }
}

extension ImageBeacon: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.ti == rhs.ti
    }
}
