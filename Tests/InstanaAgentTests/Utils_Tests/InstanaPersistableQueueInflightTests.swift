//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaAgent

class InstanaPersistableQueueInflightTests: InstanaTestCase {
    
    var queue: InstanaPersistableQueue<CoreBeacon>!
    let testIdentifier = "test.inflight.queue"
    
    override func setUp() {
        super.setUp()
        // Clean up any existing test queue
        cleanupTestQueue()
    }
    
    override func tearDown() {
        cleanupTestQueue()
        queue = nil
        super.tearDown()
    }
    
    func cleanupTestQueue() {
        if let fileURL = getCacheFileURL() {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func getCacheFileURL() -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            return nil
        }
        let filename = "\(testIdentifier).instana_queue.json"
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    // MARK: Test In-Flight Flag Cleanup on Init
    
    func test_queue_clears_inflight_flags_on_init() {
        // Given - Create queue with in-flight beacons
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacon1 = HTTPBeacon.createMock()
        let beacon2 = HTTPBeacon.createMock()
        var coreBeacon1 = try! CoreBeaconFactory(session).map(beacon1)
        var coreBeacon2 = try! CoreBeaconFactory(session).map(beacon2)
        
        coreBeacon1.markInFlight()
        coreBeacon2.markInFlight()
        
        queue.add([coreBeacon1, coreBeacon2])
        
        // Verify beacons are in-flight
        let inflightCount = queue.items.filter { $0.ifl == true }.count
        AssertEqualAndNotZero(inflightCount, 2, "Both beacons should be in-flight")
        
        // When - Create new queue instance (simulates app restart)
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - In-flight flags should be cleared
        AssertEqualAndNotZero(queue.items.count, 2, "Both beacons should be loaded")
        let stillInflight = queue.items.filter { $0.ifl == true }.count
        AssertTrue(stillInflight == 0, "No beacons should be in-flight after restart")
    }
    
    func test_queue_preserves_non_inflight_beacons_on_init() {
        // Given - Create queue with mix of in-flight and normal beacons
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacon1 = HTTPBeacon.createMock()
        let beacon2 = HTTPBeacon.createMock()
        let beacon3 = HTTPBeacon.createMock()
        
        var coreBeacon1 = try! CoreBeaconFactory(session).map(beacon1)
        let coreBeacon2 = try! CoreBeaconFactory(session).map(beacon2)
        var coreBeacon3 = try! CoreBeaconFactory(session).map(beacon3)
        
        coreBeacon1.markInFlight()
        coreBeacon3.markInFlight()
        // coreBeacon2 is not in-flight
        
        queue.add([coreBeacon1, coreBeacon2, coreBeacon3])
        
        // When - Create new queue instance
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - All beacons should be present with cleared in-flight flags
        AssertEqualAndNotZero(queue.items.count, 3, "All beacons should be loaded")
        let inflightCount = queue.items.filter { $0.ifl == true }.count
        AssertTrue(inflightCount == 0, "No beacons should be in-flight")

        // Verify beacon IDs are preserved
        let beaconIds = queue.items.map { $0.bid }.sorted()
        let expectedIds = [coreBeacon1.bid, coreBeacon2.bid, coreBeacon3.bid].sorted()
        AssertTrue(beaconIds == expectedIds, "All beacon IDs should be preserved")
    }
    
    func test_queue_handles_empty_queue_on_init() {
        // Given - Empty queue
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // When - Create new queue instance
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - Should still be empty
        AssertTrue(queue.items.isEmpty, "Queue should be empty")
    }
    
    func test_queue_handles_all_inflight_beacons_on_init() {
        // Given - Queue with all beacons in-flight
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacons = (0..<5).map { _ in HTTPBeacon.createMock() }
        var coreBeacons = try! beacons.map { try CoreBeaconFactory(session).map($0) }
        
        for i in 0..<coreBeacons.count {
            coreBeacons[i].markInFlight()
        }
        
        queue.add(coreBeacons)
        
        // Verify all are in-flight
        AssertEqualAndNotZero(queue.items.count, 5)
        AssertEqualAndNotZero(queue.items.filter { $0.ifl == true }.count, 5)
        
        // When - Create new queue instance
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - All should have cleared in-flight flags
        AssertEqualAndNotZero(queue.items.count, 5, "All beacons should be loaded")
        AssertTrue(queue.items.filter { $0.ifl == true }.count == 0, "All in-flight flags should be cleared")
    }
    
    // MARK: Test Persistence with In-Flight Flags
    
    func test_inflight_flags_persisted_to_disk() {
        // Given
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        coreBeacon.markInFlight()
        
        // When
        queue.add(coreBeacon)
        
        // Then - Read directly from file
        guard let fileURL = getCacheFileURL() else {
            XCTFail("Could not get cache file URL")
            return
        }
        
        let data = try! Data(contentsOf: fileURL)
        let loadedBeacons = try! JSONDecoder().decode([CoreBeacon].self, from: data)
        
        AssertEqualAndNotZero(loadedBeacons.count, 1)
        AssertTrue(loadedBeacons[0].ifl == true, "In-flight flag should be persisted to disk")
    }
    
    func test_inflight_flags_cleared_after_restart_simulation() {
        // Given - Simulate app lifecycle
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        coreBeacon.markInFlight()
        queue.add(coreBeacon)
        
        // Verify persisted with in-flight flag
        guard let fileURL = getCacheFileURL() else {
            XCTFail("Could not get cache file URL")
            return
        }
        
        var data = try! Data(contentsOf: fileURL)
        var loadedBeacons = try! JSONDecoder().decode([CoreBeacon].self, from: data)
        AssertTrue(loadedBeacons[0].ifl == true)
        
        // When - Simulate app restart
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - In-flight flag should be cleared in memory
        AssertTrue(queue.items.first?.ifl != true)
        
        // And persisted file should be updated on next write
        queue.write()
        
        data = try! Data(contentsOf: fileURL)
        loadedBeacons = try! JSONDecoder().decode([CoreBeacon].self, from: data)
        AssertTrue(loadedBeacons[0].ifl != true, "In-flight flag should be cleared in persisted file after write")
    }
    
    // MARK: Test Retry Count Preservation
    
    func test_retry_count_preserved_on_init() {
        // Given - Beacon with retry count
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        let beacon = HTTPBeacon.createMock()
        var coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        coreBeacon.increaseRetryCount()
        coreBeacon.increaseRetryCount()
        coreBeacon.markInFlight()
        
        queue.add(coreBeacon)
        
        // When - Restart
        queue = nil
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - Retry count should be preserved, in-flight flag cleared
        let loadedBeacon = queue.items.first!
        AssertEqualAndNotZero(loadedBeacon.rct!, 2, "Retry count should be preserved")
        AssertTrue(loadedBeacon.ifl != true, "In-flight flag should be cleared")
    }
    
    // MARK: Test flushableItemsAvailable

    func test_flushableItemsAvailable_returns_false_when_queue_is_empty() {
        // Given
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)

        // Then
        XCTAssertFalse(queue.flushableItemsAvailable())
    }

    func test_flushableItemsAvailable_returns_true_when_queue_has_nonInflight_beacon() {
        // Given
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)

        let beacon = HTTPBeacon.createMock()
        let coreBeacon = try! CoreBeaconFactory(session).map(beacon)
        queue.add(coreBeacon)

        // Then
        XCTAssertTrue(queue.flushableItemsAvailable())
    }

    func test_flushableItemsAvailable_returns_false_when_all_beacons_are_inflight() {
        // Given
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)

        let beacons = (0..<3).map { _ in HTTPBeacon.createMock() }
        var coreBeacons = try! beacons.map { try CoreBeaconFactory(session).map($0) }
        for index in coreBeacons.indices {
            coreBeacons[index].markInFlight()
        }
        queue.add(coreBeacons)

        // Then
        XCTAssertFalse(queue.flushableItemsAvailable())
    }

    func test_flushableItemsAvailable_returns_true_when_queue_has_mixed_inflight_and_nonInflight_beacons() {
        // Given
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)

        let firstBeacon = HTTPBeacon.createMock()
        let secondBeacon = HTTPBeacon.createMock()
        var firstCoreBeacon = try! CoreBeaconFactory(session).map(firstBeacon)
        let secondCoreBeacon = try! CoreBeaconFactory(session).map(secondBeacon)

        firstCoreBeacon.markInFlight()
        queue.add([firstCoreBeacon, secondCoreBeacon])

        // Then
        XCTAssertTrue(queue.flushableItemsAvailable())
    }

    // MARK: Test Edge Cases
    
    func test_queue_handles_corrupted_file_gracefully() {
        // Given - Create corrupted file
        guard let fileURL = getCacheFileURL() else {
            XCTFail("Could not get cache file URL")
            return
        }
        
        let corruptedData = "This is not valid JSON".data(using: .utf8)!
        try! corruptedData.write(to: fileURL)
        
        // When - Try to initialize queue
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then - Should start with empty queue
        AssertTrue(queue.items.isEmpty, "Queue should be empty when file is corrupted")
    }
    
    func test_queue_handles_missing_file_gracefully() {
        // Given - No existing file
        cleanupTestQueue()
        
        // When
        queue = InstanaPersistableQueue<CoreBeacon>(identifier: testIdentifier, maxItems: 100)
        
        // Then
        AssertTrue(queue.items.isEmpty, "Queue should be empty when no file exists")
    }
}
