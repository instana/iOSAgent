
import XCTest
@testable import InstanaSensor

class SessionProfileBeaconTests: XCTestCase {

    func test_map_session() {
        // Given
        let config = InstanaConfiguration.default(key: "KEY")
        let sessionID = "ID-\((0...100).randomElement() ?? 0)"
        let timestamp = Date().millisecondsSince1970
        let beacon = SessionProfileBeacon(state: .start, timestamp: timestamp, sessionId: sessionID)
        let mapper = CoreBeaconFactory(config)

        // When
        guard let sut = try? mapper.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .sessionStart)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 18)
    }

    func test_asString() {
        // Given
        let sid = "SessionID"
        let key = "KEY1234"
        let session = SessionProfileBeacon(state: .start, sessionId: sid)
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(InstanaConfiguration.default(key: key)).map(session)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nav\t\(beacon.av)\nbid\t\(beacon.bid)\nbuid\t\(beacon.buid)\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\nro\tfalse\nsid\t\(beacon.sid)\nt\tsessionStart\nti\t\(session.timestamp)\nul\ten\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }
}
