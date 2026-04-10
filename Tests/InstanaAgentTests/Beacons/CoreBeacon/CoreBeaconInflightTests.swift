//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaAgent

class CoreBeaconInflightTests: InstanaTestCase {
    
    // MARK: Test In-Flight Flag Operations
    
    func test_beacon_inflight_flag_initially_nil() {
        // Given
        let beacon = HTTPBeacon.createMock()
        
        // When
        let coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        
        // Then
        AssertTrue(coreBeacon.ifl == nil, "In-flight flag should be nil initially")
    }
    
    func test_mark_beacon_inflight() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        
        // When
        coreBeacon.markInFlight()
        
        // Then
        AssertTrue(coreBeacon.ifl == true, "In-flight flag should be true after marking")
    }
    
    func test_clear_beacon_inflight() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        coreBeacon.markInFlight()
        AssertTrue(coreBeacon.ifl == true)
        
        // When
        coreBeacon.clearInFlight()
        
        // Then
        AssertTrue(coreBeacon.ifl == nil, "In-flight flag should be nil after clearing")
    }
    
    func test_mark_and_clear_inflight_multiple_times() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        
        // When/Then - Multiple mark/clear cycles
        coreBeacon.markInFlight()
        AssertTrue(coreBeacon.ifl == true)
        
        coreBeacon.clearInFlight()
        AssertTrue(coreBeacon.ifl == nil)
        
        coreBeacon.markInFlight()
        AssertTrue(coreBeacon.ifl == true)
        
        coreBeacon.clearInFlight()
        AssertTrue(coreBeacon.ifl == nil)
    }
    
    // MARK: Test Beacon Equality with In-Flight Flag
    
    func test_beacon_equality_ignores_inflight_flag() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon1 = try! CoreBeaconFactory(session).map(beacon)
        let coreBeacon2 = coreBeacon1
        
        // When - Mark one as in-flight
        coreBeacon1.markInFlight()
        
        // Then - Should still be equal (equality based on bid)
        AssertTrue(coreBeacon1 == coreBeacon2, "Beacons should be equal regardless of in-flight flag")
        AssertTrue(coreBeacon1.bid == coreBeacon2.bid)
    }
    
    func test_beacon_hash_ignores_inflight_flag() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon1 = try! CoreBeaconFactory(session).map(beacon)
        let coreBeacon2 = coreBeacon1
        
        // When - Mark one as in-flight
        coreBeacon1.markInFlight()
        
        // Then - Should have same hash (hash based on bid)
        AssertTrue(coreBeacon1.hashValue == coreBeacon2.hashValue, "Beacons should have same hash regardless of in-flight flag")
    }
    
    // MARK: Test Set Operations with In-Flight Beacons
    
    func test_set_can_replace_beacon_with_inflight_version() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        var set = Set<CoreBeacon>()
        set.insert(coreBeacon)
        
        // When - Mark as in-flight and update set
        coreBeacon.markInFlight()
        set.remove(coreBeacon) // Remove old version (works because equality is based on bid)
        set.insert(coreBeacon) // Insert new version with in-flight flag
        
        // Then
        AssertEqualAndNotZero(set.count, 1)
        let storedBeacon = set.first!
        AssertTrue(storedBeacon.ifl == true, "Set should contain in-flight version")
    }
    
    func test_filter_inflight_beacons_from_set() {
        // Given
        let beacon1 = HTTPBeacon.createMock()
        let beacon2 = HTTPBeacon.createMock()
        let beacon3 = HTTPBeacon.createMock()
        
        var coreBeacon1 = try! CoreBeaconFactory(session).map(beacon1)
        var coreBeacon2 = try! CoreBeaconFactory(session).map(beacon2)
        let coreBeacon3 = try! CoreBeaconFactory(session).map(beacon3)
        
        coreBeacon1.markInFlight()
        coreBeacon2.markInFlight()
        
        var set = Set<CoreBeacon>()
        set.insert(coreBeacon1)
        set.insert(coreBeacon2)
        set.insert(coreBeacon3)
        
        // When - Filter out in-flight beacons
        let notInFlight = set.filter { $0.ifl != true }
        
        // Then
        AssertEqualAndNotZero(set.count, 3, "Original set should have 3 beacons")
        AssertEqualAndNotZero(notInFlight.count, 1, "Should have 1 beacon not in-flight")
        AssertTrue(notInFlight.first?.bid == coreBeacon3.bid)
    }
    
    // MARK: Test Codable with In-Flight Flag
    
    func test_beacon_with_inflight_flag_is_codable() throws {
        // Given
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        coreBeacon.markInFlight()
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(coreBeacon)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedBeacon = try decoder.decode(CoreBeacon.self, from: data)
        
        AssertTrue(decodedBeacon.ifl == true, "In-flight flag should be preserved after encoding/decoding")
        AssertTrue(decodedBeacon.bid == coreBeacon.bid)
    }
    
    func test_beacon_without_inflight_flag_is_codable() throws {
        // Given
        let beacon = HTTPBeacon.createMock()
        let coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(coreBeacon)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedBeacon = try decoder.decode(CoreBeacon.self, from: data)
        
        AssertTrue(decodedBeacon.ifl == nil, "In-flight flag should be nil after encoding/decoding")
        AssertTrue(decodedBeacon.bid == coreBeacon.bid)
    }
}
