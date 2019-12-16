
import Foundation
import XCTest
@testable import InstanaSensor

class CoreBeaconExtensionsTests: XCTestCase {

    var sessionID: UUID!
    var key: String!
    var user: InstanaProperties.User!
    var metaData: [String: String]!
    var viewName: String!
    var env: InstanaEnvironment!
    var props: InstanaProperties!
    var defaultCoreBeacon: CoreBeacon!
    var defaultWifiCoreBeacon: CoreBeacon!

    override func setUp() {
        super.setUp()
        sessionID = UUID()
        user = InstanaProperties.User(id: UUID().uuidString , email: "ex@example.com", name: "John Appleseed")
        viewName = "SomeView"
        metaData = ["MetaKey": "MetaValue"]
        key = "123KEY"
        env = InstanaEnvironment.mock(configuration: .default(key: key),
                                      sessionID: sessionID,
                                      metaData: metaData,
                                      user: user,
                                      currentView: viewName)
        props = env.propertyHandler.properties
        defaultCoreBeacon = CoreBeacon.createDefault(key: key, sessionID: sessionID, properties: props)
        defaultWifiCoreBeacon = CoreBeacon.createDefault(key: key, sessionID: sessionID, connectionType: .wifi, properties: props)
    }

    func test_asString_Default() {
        // Given
        let beacon = defaultWifiCoreBeacon!

        // When
        let sut = beacon.asString

        // Then
        let expected = "ab\t\(beacon.ab)\nav\t\(beacon.av)\nbid\t\(beacon.bid)\nbuid\t\(beacon.buid)\ncn\tNone\nct\tWifi\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key!)\nm_MetaKey\t\(metaData["MetaKey"]!)\nosn\tiOS\nosv\t\(beacon.osv)\nro\tfalse\nsid\t\(sessionID.uuidString)\nti\t\(beacon.ti)\nue\t\(user.email ?? "")\nui\t\(user.id)\nul\ten\nun\t\(user.name ?? "")\nv\t\(viewName!)\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let beacon = defaultCoreBeacon!

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
        let beacon = defaultCoreBeacon!
        let value = beacon.ab

        // When
        let sut = beacon.formattedKVPair(key: "ab", value: value)

        // When
        XCTAssertEqual(sut, "ab\t\(value)")
    }

    func test_formattedKVPair_nil_value() {
        // Given
        let beacon = defaultCoreBeacon!
        let value = Optional<Any>.none as Any

        // When
        let sut = beacon.formattedKVPair(key: "KEY", value: value)

        // When
        XCTAssertNil(sut)
    }

    func test_cleaning() {
        // Given
        var beacon = defaultCoreBeacon!
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
        var beacon = defaultCoreBeacon!
        beacon.bt = longString

        // When
        let sut = beacon.cleaning(beacon.bt) ?? ""

        // Then
        XCTAssertTrue(sut.hasSuffix("…"))
    }
}
