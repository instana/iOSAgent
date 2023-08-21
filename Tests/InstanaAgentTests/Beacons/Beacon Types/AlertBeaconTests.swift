import XCTest
@testable import InstanaAgent

class AlertBeaconTests: InstanaTestCase {

    func test_lowMemory_init() {
        // Given
        let alertType = AlertBeacon.AlertType.lowMemory
        let alert = AlertBeacon(alertType: alertType)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(alert) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .alert)
        AssertTrue(sut.ec == nil)
        AssertTrue(sut.et == nil)
        AssertTrue(sut.em == nil)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 22)
    }

    func test_asString() {
        // Given
        let alertType = AlertBeacon.AlertType.lowMemory
        let alert = AlertBeacon(alertType: alertType)
        var beacon: CoreBeacon!
        let mockedInstanaSession = InstanaSession.mock(configuration: .mock)
        do {
            beacon = try CoreBeaconFactory(mockedInstanaSession).map(alert)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\talert\nti\t\(alert.timestamp)\nuf\tc\nul\ten\nusi\t\(mockedInstanaSession.usi!.uuidString)\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let alertType = AlertBeacon.AlertType.lowMemory
        let alert = AlertBeacon(alertType: alertType)

        // When
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(alert)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }
        let mirror = Mirror(reflecting: beacon!)
        guard let sut = beacon.asJSON else { XCTFail("Cannot convert Beacon to JSON"); return }

        // Then
        AssertTrue(sut.count > 0)
        AssertTrue(sut.count == mirror.nonNilChildren.count)

        mirror.nonNilChildren.forEach { child in
            let value = child.value as AnyObject
            AssertEqualAndNotNil(sut[child.label] as? String, value.description, "Values for \(child.0) must be same")
        }
    }
}
