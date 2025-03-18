
import XCTest
@testable import InstanaAgent

class SessionProfileBeaconTests: InstanaTestCase {

    func test_map_session() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let beacon = SessionProfileBeacon(state: .start, timestamp: timestamp)
        let factory = CoreBeaconFactory(InstanaSession.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .sessionStart)
    }

    func test_asString() {
        // Given
        let mockInstanaSession = InstanaSession.mock
        let session = SessionProfileBeacon(state: .start)
        let factory = CoreBeaconFactory(mockInstanaSession)
        var beacon: CoreBeacon!
        do {
            beacon = try factory.map(session)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncas\tf\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\t\(String(InstanaSystemUtils.isDeviceJailbroken))\nsid\t\(beacon.sid)\nt\tsessionStart\nti\t\(session.timestamp)\nuf\tc,lm\nul\ten\nusi\t\(mockInstanaSession.usi!.uuidString)\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let session = SessionProfileBeacon(state: .start)
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
