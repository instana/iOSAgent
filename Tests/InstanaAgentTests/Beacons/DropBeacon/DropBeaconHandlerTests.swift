
import XCTest
@testable import InstanaAgent

class DropBeaconHandlerTests: InstanaTestCase {
    var httpBeacon: HTTPBeacon!
    var customBeacon: CustomBeacon!
    var viewBeacon: ViewChange!
    var sessionStartBeacon: SessionProfileBeacon!

    override func setUp() {
        super.setUp()

        httpBeacon = HTTPBeacon(method: "GET", url:URL.random, responseCode: 200)
        customBeacon = CustomBeacon(name: "test custom name")
        viewBeacon = ViewChange(viewName: "test view name")
        sessionStartBeacon = SessionProfileBeacon(state: .start)
    }

    func test_addBeaconToDropHandler() {
        // Given
        let dbHandler = DropBeaconHandler()

        // When
        dbHandler.addBeaconToDropHandler(beacon: httpBeacon)
        dbHandler.addBeaconToDropHandler(beacon: customBeacon)
        dbHandler.addBeaconToDropHandler(beacon: viewBeacon)

        // Then
        AssertEqualAndNotNil(dbHandler.httpUniqueMap.count, 1)
        AssertEqualAndNotNil(dbHandler.viewUniqueMap.count, 1)
        AssertEqualAndNotNil(dbHandler.customUniqueMap.count, 1)
    }

    func test_addBeaconToDropHandler_negatives() {
        // Given
        let dbHandler = DropBeaconHandler()

        // When
        dbHandler.addBeaconToDropHandler(beacon: sessionStartBeacon)

        // Then
        AssertTrue(dbHandler.droppingStartTime == 0)
    }

    func test_mergeDroppedBeacons() {
        // Given
        let dbHandler = DropBeaconHandler()
        dbHandler.MIN_BEACONS_REQUIRED = 0

        // When
        dbHandler.addBeaconToDropHandler(beacon: httpBeacon)
        dbHandler.addBeaconToDropHandler(beacon: customBeacon)
        dbHandler.addBeaconToDropHandler(beacon: viewBeacon)
        AssertEqualAndNotNil(dbHandler.httpUniqueMap.count, 1)
        AssertEqualAndNotNil(dbHandler.viewUniqueMap.count, 1)
        AssertEqualAndNotNil(dbHandler.customUniqueMap.count, 1)
        let sut = dbHandler.mergeDroppedBeacons()

        // Then
        AssertTrue(sut != nil)
        AssertTrue(dbHandler.droppingStartTime == 0)
        AssertTrue(dbHandler.droppingStartView == nil)
        AssertEqualAndNotNil(dbHandler.httpUniqueMap.count, 0)
        AssertEqualAndNotNil(dbHandler.viewUniqueMap.count, 0)
        AssertEqualAndNotNil(dbHandler.customUniqueMap.count, 0)
    }

    func test_mergeDroppedBeacons_negatives() {
        // Given
        let dbHandler = DropBeaconHandler()
        dbHandler.droppingStartTime = 1234567

        // When
        let sut = dbHandler.mergeDroppedBeacons()

        // Then
        AssertTrue(sut == nil)
    }

    func test_saveDroppedBeacons() {
        // Given
        let oldViewBeacon = ViewChange(timestamp: Date.distantPast.millisecondsSince1970,
                                   viewName: "test view name")
        let alpahaFirstViewBeacon = ViewChange(timestamp: Date.distantFuture.millisecondsSince1970,
                                   viewName: "a test view name")
        let newerViewBeacon = ViewChange(timestamp: Date.distantFuture.millisecondsSince1970,
                                   viewName: "test view name")
        let dbHandler = DropBeaconHandler()

        // When
        dbHandler.addBeaconToDropHandler(beacon: viewBeacon)
        dbHandler.addBeaconToDropHandler(beacon: oldViewBeacon)
        dbHandler.addBeaconToDropHandler(beacon: alpahaFirstViewBeacon)
        dbHandler.addBeaconToDropHandler(beacon: newerViewBeacon)

        // Then
        AssertTrue(dbHandler.viewUniqueMap.count == 2)

        // Next
        let sut = dbHandler.mergeDroppedBeacons()

        // Then
        AssertTrue(sut != nil)
    }
}
