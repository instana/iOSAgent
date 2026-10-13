//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
@_spi(Internal) import InstanaAgent

final class TrackedNSCache {
    private let cache = NSCache<NSNumber, NSNumber>()
    private var keySet: Set<UInt64> = []
    var allKeys: [UInt64] {
        Array(keySet)
    }

    init(countLimit: Int = 180) {
        cache.countLimit = countLimit
    }

    func insert(_ key: UInt64, value: Instana.Types.Milliseconds) {
        keySet.insert(key)
        cache.setObject(NSNumber(value: value), forKey: NSNumber(value: key))
    }

    func contains(_ key: UInt64) -> Bool {
        keySet.contains(key)
    }

    func remove(_ key: UInt64) {
        keySet.remove(key)
        cache.removeObject(forKey: NSNumber(value: key))
    }

    func removeAll() {
        keySet.removeAll()
        cache.removeAllObjects()
    }

    func findSimilarKey(for key: UInt64, hammingDistance: Int) -> UInt64? {
        var minDistance = hammingDistance + 1
        var foundKey: UInt64?

        // Loop over keys like dictionary (from keySet)
        for candidateKey in keySet {
            let distance = (key ^ candidateKey).nonzeroBitCount
            if distance <= minDistance {
                minDistance = distance
                foundKey = candidateKey
            }
        }

        guard let foundKey, minDistance <= hammingDistance else { return nil }
        return foundKey
    }
}
