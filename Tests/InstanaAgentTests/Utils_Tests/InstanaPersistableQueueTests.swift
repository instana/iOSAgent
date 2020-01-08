
import Foundation
import XCTest
@testable import InstanaAgent

class InstanaPersistableQueueTests: XCTestCase {

    func test_add_read_Queue_single() {
        // Given
        let exp = expectation(description: "test_add_read_Queue_single")
        let corebeacons = createCoreBeacons()
        let queueHandler = InstanaPersistableQueue<CoreBeacon>()
        let singleBeacon = corebeacons.first!
        queueHandler.removeAll()

        // When
        queueHandler.removeAll()
        queueHandler.add(singleBeacon) {result in
            AssertTrue(result.error == nil)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.4)

        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.first == singleBeacon)
        AssertTrue(storedBeacons.count == 1)
    }

    func test_add_read_Queue_multiple() {
        // Given
        let exp = expectation(description: "test_add_read_Queue_multiple")
        let corebeacons = createCoreBeacons()
        let queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()

        // When
        queueHandler.add(corebeacons) {result in
            AssertTrue(result.error == nil)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.4)

        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons == corebeacons)
        AssertTrue(storedBeacons.count == 3)
    }

    //
    // When creating a new Queue instance, we expect the old stored beacons that haven't been transmitted
    //
    func test_add_read_Queue_adding_persisted_beacons_at_init() {
        // Given
        let firstExp = expectation(description: "test_add_read_Queue_adding_persisted_beacons_at_init_1")
        let secondExp = expectation(description: "test_add_read_Queue_adding_persisted_beacons_at_init_2")
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()
        queueHandler.add(corebeacons) {_ in
            firstExp.fulfill()
        }
        wait(for: [firstExp], timeout: 0.5)

        // When
        queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.add(corebeacons) {result in
            AssertTrue(result.error == nil)
            secondExp.fulfill()
        }
        wait(for: [secondExp], timeout: 1.0)

        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count * 2)
    }

    func test_removeAll() {
        // Given
        let exp = expectation(description: "test_removeAll")
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.add(corebeacons)

        // When
        queueHandler.removeAll() {result in
            AssertTrue(result.error == nil)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.4)

        // Then
        var storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.isEmpty)

        // The removal should also be persisted
        // When creating a new instance
        queueHandler = InstanaPersistableQueue<CoreBeacon>()

        // Then
        storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.isEmpty)
    }

    func test_remove_last() {
        // Given
        let exp = expectation(description: "test_remove_last")
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()
        queueHandler.add(corebeacons)

        // When
        queueHandler.remove([queueHandler.items.last!]) {result in
            AssertTrue(result.error == nil)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.4)

        // Then
        var storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count - 1)
        AssertTrue(storedBeacons.last != corebeacons.last!)

        // The removal should also be persisted
        // When creating a new instance
        queueHandler = InstanaPersistableQueue<CoreBeacon>()

        // Then
        storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count - 1)
        AssertTrue(storedBeacons.last != corebeacons.last!)
    }

    // MARK: Helper
    func createCoreBeacons() -> [CoreBeacon] {
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        do {
            return try CoreBeaconFactory(InstanaEnvironment.mock).map(beacons)
        } catch {
            XCTFail("Could not create CoreBeacons")
        }
        return []
    }

    func readStoredCoreBeacons() -> [CoreBeacon] {
        // Then
        do {
            let items = try InstanaPersistableQueue<CoreBeacon>.deserialize()
            return items
        } catch {
            XCTFail("Could not read queue")
        }
        return []
    }
}
