
import Foundation
import XCTest
@testable import InstanaSensor

class CoreBeaconExtensionsTests: XCTestCase {

    func test_asString_Default() {
        // Given
        let key = "123KEY"
        let beacon = CoreBeacon.createDefault(key: key, connectionType: .wifi)

        // When
        let sut = beacon.asString

        // Then
        let expected = "ab\t\(beacon.ab)\nav\t\(beacon.av)\nbid\t\(beacon.bid)\nbuid\t\(beacon.buid)\ncn\tNone\nct\tWifi\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\nro\tfalse\nsid\t\(beacon.sid)\nti\t\(beacon.ti)\nul\ten\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let key = "123KEY"
        let beacon = CoreBeacon.createDefault(key: key)

        // When
        let mirror = Mirror(reflecting: beacon)
        guard let sut = beacon.asJSON else { XCTFail("Cannot convert Beacon to JSON"); return }

        // Then
        AssertTrue(sut.count > 0)
        AssertTrue(sut.count == mirror.nonNilChildren.count)

        mirror.nonNilChildren.forEach { child in
            AssertEqualAndNotNil(sut[child.0] as? String, child.1 as? String, "Values for \(child.0) must be same")
        }
    }

    func test_formattedKVPair() {
        // Given
        let beacon = CoreBeacon.createDefault(key: "KEY123")
        let value = beacon.ab

        // When
        let sut = beacon.formattedKVPair(key: "ab", value: value)

        // When
        XCTAssertEqual(sut, "ab\t\(value)")
    }

    func test_formattedKVPair_nil_value() {
        // Given
        let beacon = CoreBeacon.createDefault(key: "KEY123")
        let value = Optional<Any>.none as Any

        // When
        let sut = beacon.formattedKVPair(key: "KEY", value: value)

        // When
        XCTAssertNil(sut)
    }

    func test_cleaning() {
        // Given
        var beacon = CoreBeacon.createDefault(key: "KEY123")
        beacon.bt = """

                        Trace ab

                    """

        // When
        let sut = beacon.cleaning(beacon.bt)

        // Then
        XCTAssertEqual(beacon.bt, "\n    Trace ab\n")
        XCTAssertEqual(sut, "Trace ab")
    }

    func test_truncate_at_max_length() {
        // Given
        let longString = (0...CoreBeacon.maxBytesPerField).map {"\($0)"}.joined()
        var beacon = CoreBeacon.createDefault(key: "KEY123")
        beacon.bt = longString

        // When
        let sut = beacon.cleaning(beacon.bt) ?? ""

        // Then
        XCTAssertTrue(sut.hasSuffix("…"))
    }
}
