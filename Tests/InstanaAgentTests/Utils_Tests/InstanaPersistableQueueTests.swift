//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaPersistableQueueTests: InstanaTestCase {

    func test_add_read_Queue_single() {
        // Given
        let corebeacons = createCoreBeacons()
        let queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        let singleBeacon = corebeacons.first!
        queueHandler.removeAll()

        // When
        queueHandler.removeAll()
        queueHandler.add(singleBeacon) {result in
            AssertTrue(result.error == nil)
        }

        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.first == singleBeacon)
        AssertTrue(storedBeacons.count == 1)
    }

    func test_add_read_Queue_multiple() {
        // Given
        let corebeacons = createCoreBeacons().sorted(by: {$0.bid > $1.bid})
        let queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.removeAll()

        // When
        queueHandler.add(corebeacons) {result in
            AssertTrue(result.error == nil)
        }

        // Then
        let storedBeacons = readStoredCoreBeacons().sorted(by: {$0.bid > $1.bid})
        AssertTrue(storedBeacons == corebeacons)
        AssertTrue(storedBeacons.count == 3)
    }

    func test_add_Queue_ignore_dups() {
        // Given
        let sessionID = UUID()
        let id = Beacon.generateUniqueIdImpl()
        let beacon1 = CoreBeacon.createDefault(viewName: "View_1", key: "Key_1", timestamp: 0,
                                 sid: sessionID, usi: session.usi, id: id, mobileFeatures: "c")
        let beacon2 = CoreBeacon.createDefault(viewName: "View_2", key: "Key_2", timestamp: 0,
                                 sid: sessionID, usi: session.usi, id: id, mobileFeatures: "c")
        let queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.removeAll()

        // When
        queueHandler.add([beacon1, beacon2]) {result in
            AssertTrue(result.error == nil)
        }

        // Then - only one should be added since the 2nd has the ID
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.first == beacon1)
        AssertTrue(storedBeacons.count == 1)
    }

    //
    // When creating a new Queue instance, we expect the old (persisted) beacons + new beacons
    //
    func test_persisted_beacons_plus_new() {
        // Given
        let oldBeacons = [CoreBeacon.createDefault(viewName: "V", key: "K", timestamp: 1, sid: UUID(),
                          usi: session.usi, id: Beacon.generateUniqueIdImpl(), mobileFeatures: "c")]
        var queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.removeAll()
        queueHandler.add(oldBeacons) {_ in}

        // When
        let newBeacons = [CoreBeacon.createDefault(viewName: "V", key: "K", timestamp: 2, sid: UUID(),
                          usi: session.usi, id: Beacon.generateUniqueIdImpl(), mobileFeatures: "c")]
        queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.add(newBeacons) {result in
            AssertTrue(result.error == nil)
        }

        // Then
        let storedBeacons = readStoredCoreBeacons().sorted(by: {$0.ti < $1.ti})
        AssertTrue(storedBeacons == oldBeacons + newBeacons)
    }

    //
    // When creating a new Queue instance, we expect the old (persisted) beacons - but new (same ID) should be ignored
    //
    func test_persisted_beacons_avoid_dups() {
        // Given
        let id = Beacon.generateUniqueIdImpl()
        let oldBeacons = [CoreBeacon.createDefault(viewName: "V", key: "K", timestamp: 1,
                                     sid: UUID(), usi: session.usi, id: id, mobileFeatures: "c")]
        var queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.removeAll()
        queueHandler.add(oldBeacons) {_ in}

        // When
        let newBeacon = CoreBeacon.createDefault(viewName: "V", key: "K", timestamp: 2,
                                   sid: UUID(), usi: session.usi, id: id, mobileFeatures: "c")
        queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.add(newBeacon) {result in
            AssertTrue(result.error == nil)
        }

        // Then
        let storedBeacons = readStoredCoreBeacons().sorted(by: {$0.ti < $1.ti})
        AssertTrue(storedBeacons == oldBeacons)
    }

    func test_removeAll() {
        // Given
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.add(corebeacons)

        // When
        queueHandler.removeAll() {result in
            AssertTrue(result.error == nil)
        }

        // Then
        var storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.isEmpty)

        // The removal should also be persisted
        // When creating a new instance
        queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)

        // Then
        storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.isEmpty)
    }

    func test_remove_last() {
        // Given
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 100)
        queueHandler.removeAll()
        queueHandler.add(corebeacons)
        let last = Array(queueHandler.items).last!

        // When
        queueHandler.remove([last]) {result in
            AssertTrue(result.error == nil)
        }

        // Then
        var storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count - 1)
        AssertTrue(!storedBeacons.contains(last))

        // The removal should also be persisted
        // When creating a new instance
        queueHandler = InstanaPersistableQueue<CoreBeacon>(identifier: "queue",maxItems: 100)

        // Then
        storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count - 1)
        AssertTrue(!storedBeacons.contains(last))
    }

    // MARK: Helper
    func createCoreBeacons() -> [CoreBeacon] {
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        do {
            return try CoreBeaconFactory(InstanaSession.mock).map(beacons)
        } catch {
            XCTFail("Could not create CoreBeacons")
        }
        return []
    }

    func readStoredCoreBeacons() -> [CoreBeacon] {
        // Then
        do {
            let items = try InstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 10).deserialize()
            return items
        } catch {
            XCTFail("Could not read queue")
        }
        return []
    }
}
