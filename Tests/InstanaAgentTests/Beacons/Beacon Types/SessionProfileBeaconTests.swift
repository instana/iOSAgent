
import XCTest
@testable import InstanaAgent

class SessionProfileBeaconTests: InstanaTestCase {

    func test_map_session() {
        // Given
        let sessionID = UUID()
        let timestamp = Date().millisecondsSince1970
        let beacon = SessionProfileBeacon(state: .start, timestamp: timestamp, sessionID: sessionID)
        let factory = CoreBeaconFactory(InstanaSession.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .sessionStart)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 20)
    }

    func test_asString() {
        // Given
        let session = SessionProfileBeacon(state: .start, sessionID: sessionID)
        let factory = CoreBeaconFactory(InstanaSession.mock)
        var beacon: CoreBeacon!
        do {
            beacon = try factory.map(session)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\tfalse\nsid\t\(sessionID.uuidString)\nt\tsessionStart\nti\t\(session.timestamp)\nul\ten\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let session = SessionProfileBeacon(state: .start, sessionID: sessionID)
        let factory = CoreBeaconFactory(InstanaSession.mock)
        var beacon: CoreBeacon!
        do {
            beacon = try factory.map(session)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
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
