//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

class TrackedNSCacheTests: XCTestCase {

    var cache: TrackedNSCache!

    override func setUp() {
        super.setUp()
        cache = TrackedNSCache()
    }

    override func tearDown() {
        cache = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_defaultCountLimit_cacheIsEmpty() {
        XCTAssertTrue(cache.allKeys.isEmpty)
    }

    func test_init_customCountLimit_cacheIsEmpty() {
        let custom = TrackedNSCache(countLimit: 10)
        XCTAssertTrue(custom.allKeys.isEmpty)
    }

    // MARK: - insert

    func test_insert_singleKey_appearsInAllKeys() {
        cache.insert(1, value: 1000)

        XCTAssertEqual(cache.allKeys.count, 1)
        XCTAssertTrue(cache.allKeys.contains(1))
    }

    func test_insert_multipleDistinctKeys_allAppearInAllKeys() {
        cache.insert(1, value: 100)
        cache.insert(2, value: 200)
        cache.insert(3, value: 300)

        XCTAssertEqual(cache.allKeys.count, 3)
        XCTAssertTrue(cache.allKeys.contains(1))
        XCTAssertTrue(cache.allKeys.contains(2))
        XCTAssertTrue(cache.allKeys.contains(3))
    }

    func test_insert_sameKeyTwice_appearsOnlyOnceInAllKeys() {
        cache.insert(42, value: 100)
        cache.insert(42, value: 200)   // update access time — keySet is a Set, so no duplicate

        XCTAssertEqual(cache.allKeys.count, 1)
        XCTAssertTrue(cache.allKeys.contains(42))
    }

    // MARK: - contains

    func test_contains_keyPresent_returnsTrue() {
        cache.insert(7, value: 500)

        XCTAssertTrue(cache.contains(7))
    }

    func test_contains_keyAbsent_returnsFalse() {
        XCTAssertFalse(cache.contains(99))
    }

    func test_contains_afterRemove_returnsFalse() {
        cache.insert(5, value: 500)
        cache.remove(5)

        XCTAssertFalse(cache.contains(5))
    }

    // MARK: - remove

    func test_remove_existingKey_removesFromAllKeys() {
        cache.insert(10, value: 1000)
        cache.insert(20, value: 2000)

        cache.remove(10)

        XCTAssertEqual(cache.allKeys.count, 1)
        XCTAssertFalse(cache.allKeys.contains(10))
        XCTAssertTrue(cache.allKeys.contains(20))
    }

    func test_remove_nonExistentKey_doesNotCrashOrAlterCache() {
        cache.insert(1, value: 100)

        cache.remove(999)  // key not present — must be silent no-op

        XCTAssertEqual(cache.allKeys.count, 1)
        XCTAssertTrue(cache.allKeys.contains(1))
    }

    func test_remove_onEmptyCache_doesNotCrash() {
        cache.remove(0)  // must not crash
        XCTAssertTrue(cache.allKeys.isEmpty)
    }

    // MARK: - removeAll

    func test_removeAll_clearsAllKeysAndContains() {
        cache.insert(1, value: 100)
        cache.insert(2, value: 200)
        cache.insert(3, value: 300)

        cache.removeAll()

        XCTAssertTrue(cache.allKeys.isEmpty)
        XCTAssertFalse(cache.contains(1))
        XCTAssertFalse(cache.contains(2))
        XCTAssertFalse(cache.contains(3))
    }

    func test_removeAll_onEmptyCache_doesNotCrash() {
        cache.removeAll()
        XCTAssertTrue(cache.allKeys.isEmpty)
    }

    func test_removeAll_thenInsert_works() {
        cache.insert(1, value: 100)
        cache.removeAll()

        cache.insert(2, value: 200)

        XCTAssertEqual(cache.allKeys.count, 1)
        XCTAssertTrue(cache.allKeys.contains(2))
    }

    // MARK: - allKeys

    func test_allKeys_returnsAllInsertedKeys() {
        let keys: [UInt64] = [10, 20, 30, 40]
        keys.forEach { cache.insert($0, value: Instana.Types.Milliseconds($0)) }

        let result = Set(cache.allKeys)
        XCTAssertEqual(result, Set(keys))
    }

    func test_allKeys_isEmpty_onFreshCache() {
        XCTAssertEqual(cache.allKeys.count, 0)
    }

    // MARK: - findSimilarKey: no match

    func test_findSimilarKey_emptyCache_returnsNil() {
        let result = cache.findSimilarKey(for: 0b1111, hammingDistance: 4)
        XCTAssertNil(result)
    }

    func test_findSimilarKey_exactMatch_distanceZero_returnsKey() {
        let key: UInt64 = 0b10101010
        cache.insert(key, value: 1000)

        let result = cache.findSimilarKey(for: key, hammingDistance: 0)

        XCTAssertEqual(result, key)
    }

    func test_findSimilarKey_hammingDistanceZero_differentKey_returnsNil() {
        // candidate differs by 1 bit; threshold is 0 → no match
        let stored: UInt64  = 0b00000001
        let query: UInt64   = 0b00000011   // 1 bit different
        cache.insert(stored, value: 1000)

        let result = cache.findSimilarKey(for: query, hammingDistance: 0)

        XCTAssertNil(result)
    }

    func test_findSimilarKey_withinHammingDistance_returnsCandidate() {
        // stored and query differ by exactly 2 bits; threshold is 2 → match
        let stored: UInt64 = 0b00001111
        let query: UInt64  = 0b00000011   // bits 2 and 3 differ → distance = 2
        cache.insert(stored, value: 1000)

        let result = cache.findSimilarKey(for: query, hammingDistance: 2)

        XCTAssertEqual(result, stored)
    }

    func test_findSimilarKey_exceedsHammingDistance_returnsNil() {
        // stored and query differ by 3 bits; threshold is 2 → no match
        let stored: UInt64 = 0b00001111
        let query: UInt64  = 0b00000000   // bits 0-3 differ → distance = 4
        cache.insert(stored, value: 1000)

        let result = cache.findSimilarKey(for: query, hammingDistance: 2)

        XCTAssertNil(result)
    }

    func test_findSimilarKey_exactlyAtThreshold_returnsCandidate() {
        // distance == hammingDistance should match (condition is <=)
        let stored: UInt64 = 0b11110000
        let query: UInt64  = 0b00110000   // bits 4 and 5 differ → distance = 2
        cache.insert(stored, value: 1000)

        let result = cache.findSimilarKey(for: query, hammingDistance: 2)

        XCTAssertEqual(result, stored)
    }

    func test_findSimilarKey_multipleCandidates_returnsClosest() {
        // closest:  stored1 differs by 1 bit
        // farther:  stored2 differs by 3 bits
        // Both are within threshold 3; closest should win.
        let query: UInt64   = 0b00000000
        let stored1: UInt64 = 0b00000001   // distance 1 (closest)
        let stored2: UInt64 = 0b00000111   // distance 3
        cache.insert(stored1, value: 100)
        cache.insert(stored2, value: 200)

        let result = cache.findSimilarKey(for: query, hammingDistance: 3)

        XCTAssertEqual(result, stored1)
    }

    func test_findSimilarKey_allCandidatesBeyondThreshold_returnsNil() {
        cache.insert(0b11111111, value: 100)   // distance 8 from 0
        cache.insert(0b11110000, value: 200)   // distance 4 from 0

        let result = cache.findSimilarKey(for: 0, hammingDistance: 3)

        XCTAssertNil(result)
    }

    func test_findSimilarKey_afterRemove_doesNotReturnRemovedKey() {
        let key: UInt64 = 0b00001111
        cache.insert(key, value: 1000)
        cache.remove(key)

        let result = cache.findSimilarKey(for: key, hammingDistance: 0)

        XCTAssertNil(result)
    }

    func test_findSimilarKey_afterRemoveAll_returnsNil() {
        cache.insert(0b00001111, value: 1000)
        cache.removeAll()

        let result = cache.findSimilarKey(for: 0b00001111, hammingDistance: 4)

        XCTAssertNil(result)
    }

    func test_findSimilarKey_maxUInt64Key_doesNotCrash() {
        let key = UInt64.max
        cache.insert(key, value: 9999)

        let result = cache.findSimilarKey(for: key, hammingDistance: 0)

        XCTAssertEqual(result, key)
    }

    func test_findSimilarKey_zeroKey_exactMatch() {
        cache.insert(0, value: 1000)

        let result = cache.findSimilarKey(for: 0, hammingDistance: 0)

        XCTAssertEqual(result, 0)
    }
}
