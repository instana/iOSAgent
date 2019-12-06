
import Foundation
import XCTest
@testable import InstanaSensor

class InstanaPersistableQueueTests: XCTestCase {

    func test_write_read_Queue() {
        // Given
        var corebeacons: [CoreBeacon]!
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        do {
            corebeacons = try CoreBeaconFactory(InstanaConfiguration.default(key: "KEY")).map(beacons)
        } catch {
            XCTFail("Could not create CoreBeacons")
        }
        let queueHandler = InstanaPersistableQueue<CoreBeacon>(corebeacons)

        // When
        queueHandler.write()

        // Then
        do {
            let readModel = try InstanaPersistableQueue<CoreBeacon>.read()
            AssertTrue(readModel.items == corebeacons)
        } catch {
            XCTFail("Could not read queue")
        }
    }

    // TODO: Test with integration
    // 2. flushing queue (success) and having an empty persistend queue
    // 3. Flushing queue with error (queue should not be empty at the end)
    // Try consider moving the queue code to a real QueueHandler class
}
