
import XCTest
@testable import InstanaAgent

class CoreBeaconTests: XCTestCase {

    var key: String!
    var user: InstanaProperties.User!
    var metaData: [String: String]!
    var viewName: String!
    var env: InstanaEnvironment!
    var props: InstanaProperties!
    var coreBeacon: CoreBeacon!
    var timestamp: Int64!
    var sessionID: UUID!
    var beaconID: UUID!

    override func setUp() {
        super.setUp()
        sessionID = UUID()
        beaconID = UUID()
        timestamp = Date().millisecondsSince1970

        user = InstanaProperties.User(id: sessionID.uuidString , email: "ex@example.com", name: "John Appleseed")
        viewName = "SomeView"
        metaData = ["FirstKey": "FirstValue", "SecondKey": "SecondValue"]
        key = "123KEY"
        env = InstanaEnvironment.mock(configuration: .default(key: key),
                                      sessionID: sessionID,
                                      metaData: metaData,
                                      user: user,
                                      currentView: viewName)
        props = env.propertyHandler.properties

        coreBeacon = CoreBeacon.createDefault(key: key,
                                                     timestamp: timestamp,
                                                     sessionID: sessionID,
                                                     id: beaconID,
                                                     properties: props)
    }

    func test_create_default() {
        // Given
        let sut = coreBeacon!

        // Then
        AssertEqualAndNotNil(sut.k, key)
        AssertEqualAndNotNil(sut.ti, String(timestamp))
        AssertEqualAndNotNil(sut.sid, sessionID.uuidString)
        AssertEqualAndNotNil(sut.bid, beaconID.uuidString)
        AssertEqualAndNotNil(sut.buid, InstanaSystemUtils.applicationBundleIdentifier)
        AssertEqualAndNotNil(sut.ul, Locale.current.languageCode)
        AssertEqualAndNotNil(sut.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(sut.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(sut.osn, InstanaSystemUtils.systemName)
        AssertEqualAndNotNil(sut.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(sut.dmo, InstanaSystemUtils.deviceModel)
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.ro, String(InstanaSystemUtils.isDeviceJailbroken))
        AssertEqualAndNotNil(sut.vw, String(Int(InstanaSystemUtils.screenSize.width)))
        AssertEqualAndNotNil(sut.vh, String(Int(InstanaSystemUtils.screenSize.height)))
        AssertEqualAndNotNil(sut.cn, InstanaSystemUtils.networkUtility.connectionType.cellular.carrierName)
        AssertEqualAndNotNil(sut.ct, InstanaSystemUtils.networkUtility.connectionType.description)

        AssertEqualAndNotNil(sut.ue, user?.email)
        AssertEqualAndNotNil(sut.un, user?.name)
        AssertEqualAndNotNil(sut.ui, user?.id)

        AssertEqualAndNotNil(sut.m?["FirstKey"], metaData["FirstKey"])
        AssertEqualAndNotNil(sut.m?["SecondKey"], metaData["SecondKey"])

        AssertEqualAndNotNil(sut.v, viewName)
    }

    func testNumberOfFields_all() {
        // Given
        let sut = coreBeacon!


        // When
        let values = Mirror(reflecting: sut).children

        // Then
        XCTAssertEqual(values.count, 35)
    }

    func testNumberOfFields_non_nil() {
        // Given
        let sut = coreBeacon!

        // When
        let values = Array(Mirror(reflecting: sut).nonNilChildren)

        // Then
        XCTAssertEqual(values.count, 22)
    }


    func test_all_existence_of_all_field_keys() {
        // Given
        let sut = coreBeacon!

        let expectedKeys = ["t", "v", "bt", "k" ,"ti", "sid", "bid", "buid", "m", "ui", "un", "ue", "ul", "ab", "av", "osn", "osv", "dma", "dmo", "ro", "vw", "vh", "cn", "ct", "hu", "hp", "hm", "hs", "ebs", "dbs", "trs", "d", "ec", "em", "et"]
        // When
        let keys = Mirror(reflecting: sut).children.compactMap {$0.label}

        // Then
        let matchingKeys = expectedKeys.filter {key in
            keys.contains(key)
        }

        XCTAssertEqual(expectedKeys.count, matchingKeys.count)
    }
}
