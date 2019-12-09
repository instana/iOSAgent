
import Foundation
import XCTest
@testable import InstanaSensor

class InstanaPersistableQueueTests: XCTestCase {

    func test_add_read_Queue_single() {
        // Given
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        let singleBeacon = corebeacons.first!
        queueHandler.removeAll()

        // When
        queueHandler.removeAll()
        queueHandler.add(singleBeacon)


        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.first == singleBeacon)
        AssertTrue(storedBeacons.count == 1)
    }

    func test_add_read_Queue_multiple() {
        // Given
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()

        // When
        queueHandler.add(corebeacons)

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
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()
        queueHandler.add(corebeacons)

        // When
        queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.add(corebeacons)

        // Then
        let storedBeacons = readStoredCoreBeacons()
        AssertTrue(storedBeacons.count == corebeacons.count * 2)
    }

    func test_removeAll() {
        // Given
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.add(corebeacons)

        // When
        queueHandler.removeAll()

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
        let corebeacons = createCoreBeacons()
        var queueHandler = InstanaPersistableQueue<CoreBeacon>()
        queueHandler.removeAll()
        queueHandler.add(corebeacons)

        // When
        queueHandler.remove([queueHandler.items.last!])

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
            return try CoreBeaconFactory(InstanaConfiguration.default(key: "KEY")).map(beacons)
        } catch {
            XCTFail("Could not create CoreBeacons")
        }
        return []
    }

    func readStoredCoreBeacons() -> [CoreBeacon] {
        // Then
        do {
            let readModel = try InstanaPersistableQueue<CoreBeacon>.read()
            return readModel.items
        } catch {
            XCTFail("Could not read queue")
        }
        return []
    }
}
