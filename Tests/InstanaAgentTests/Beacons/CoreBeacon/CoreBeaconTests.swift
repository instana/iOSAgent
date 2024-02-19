
import XCTest
@testable import InstanaAgent

class CoreBeaconTests: InstanaTestCase {

    var user: InstanaProperties.User!
    var metaData: [String: String]!
    var viewName: String!
    var props: InstanaProperties!
    var coreBeacon: CoreBeacon!
    var wifiCoreBeacon: CoreBeacon!
    var timestamp: Int64!
    var beaconID: String = ""

    override func setUp() {
        super.setUp()
        beaconID = Beacon.generateUniqueIdImpl()
        timestamp = Date().millisecondsSince1970

        user = InstanaProperties.User(id: sessionID.uuidString , email: "ex@example.com", name: "John Appleseed")
        viewName = "SomeView"
        metaData = ["MetaKey": "MetaValue"]
        session = InstanaSession.mock(configuration: config,
                                      sessionID: sessionID,
                                      metaData: metaData,
                                      user: user,
                                      currentView: viewName)
        props = session.propertyHandler.properties
        coreBeacon = CoreBeacon.createDefault(viewName: viewName,
                                              key: key,
                                              timestamp: timestamp,
                                              sid: sessionID,
                                              usi: session.usi,
                                              id: beaconID,
                                              mobileFeatures: "c",
                                              hybridAgentId: nil,
                                              hybridAgentVersion: nil)
        coreBeacon.append(props)
        wifiCoreBeacon = CoreBeacon.createDefault(viewName: viewName,
                                                  key: key,
                                                  timestamp: timestamp,
                                                  sid: sessionID,
                                                  usi: session.usi,
                                                  id: beaconID,
                                                  mobileFeatures: "c",
                                                  hybridAgentId: "f",
                                                  hybridAgentVersion: "3.0.6",
                                                  connection: .wifi,
                                                  ect: .fiveG)
        wifiCoreBeacon.append(props)
    }

    func test_create_default() {
        // Given
        let sut = coreBeacon!

        // Then
        AssertEqualAndNotNil(sut.k, key)
        AssertEqualAndNotNil(sut.ti, String(timestamp))
        AssertEqualAndNotNil(sut.sid, sessionID.uuidString)
        XCTAssertNotNil(sut.usi)
        AssertEqualAndNotNil(sut.bid, beaconID)
        AssertEqualAndNotNil(sut.bi, InstanaSystemUtils.applicationBundleIdentifier)
        AssertEqualAndNotNil(sut.uf, "c")
        AssertEqualAndNotNil(sut.ul, Locale.current.languageCode)
        AssertEqualAndNotNil(sut.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(sut.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(sut.p, InstanaSystemUtils.systemName)
        AssertEqualAndNotNil(sut.osn, InstanaSystemUtils.systemName)
        AssertEqualAndNotNil(sut.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(sut.dmo, InstanaSystemUtils.deviceModel)
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.agv, InstanaSystemUtils.agentVersion)
        AssertEqualAndNotNil(sut.ro, String(InstanaSystemUtils.isDeviceJailbroken))
        AssertEqualAndNotNil(sut.vw, String(Int(InstanaSystemUtils.screenSize.width)))
        AssertEqualAndNotNil(sut.vh, String(Int(InstanaSystemUtils.screenSize.height)))
        AssertEqualAndNotNil(sut.cn, NetworkUtility.CellularType.current.carrierName)
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
        XCTAssertEqual(values.count, 48)
    }

    func testNumberOfFields_non_nil() {
        // Given
        let sut = coreBeacon!

        // When
        let values = Array(Mirror(reflecting: sut).nonNilChildren)

        // Then
        XCTAssertEqual(values.count, 26)
    }


    func test_all_existence_of_all_field_keys() {
        // Given
        let sut = coreBeacon!

        let expectedKeys = ["t", "v", "bt", "k" ,"ti", "sid", "usi", "bid", "uf", "bi", "m", "ui", "un",
                            "ue", "ul", "ab", "av", "p", "osn", "osv", "dma", "dmo", "ro", "vw", "vh",
                            "cn", "ct", "ect", "hu", "hp", "hm", "hs", "ebs", "dbs", "trs", "d",
                            "ec", "em", "et", "agv", "cen", "cm", "h", "ast", "cid", "cti", "dt", "st"]
        // When
        let keys = Mirror(reflecting: sut).children.compactMap {$0.label}

        // Then
        XCTAssertTrue(keys.count > 0)
        keys.forEach {existingCoreBeaconKey in
            XCTAssertTrue(expectedKeys.contains(existingCoreBeaconKey),
                          "CoreBeacon Key \(existingCoreBeaconKey) not expected")
        }
        expectedKeys.forEach {expectedKey in
            XCTAssertTrue(keys.contains(expectedKey),
                          "Expected Key \(expectedKey) not available in CoreBeacon")
        }
    }

    func test_usiNotAllowed() {
        // Given
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: usiTrackingNotAllowed,
                                             hybridAgentId: nil,
                                             hybridAgentVersion: nil)
        let sessionUsi = InstanaSession.mock(configuration: configUsi,
                                      sessionID: sessionID,
                                      metaData: metaData,
                                      user: user,
                                      currentView: viewName)
        var beacon = CoreBeacon.createDefault(viewName: viewName,
                                      key: key,
                                      timestamp: timestamp,
                                      sid: sessionID,
                                      usi: sessionUsi.usi,
                                      id: beaconID,
                                      mobileFeatures: "c",
                                      hybridAgentId: "nil",
                                      hybridAgentVersion: nil,
                                      connection: .wifi,
                                      ect: .fiveG)
        beacon.append(props)

        // When
        let sut = beacon.asString

        // Then
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncn\tNone\nct\twifi\ndma\tApple\ndmo\t\(beacon.dmo)\nect\t5g\nk\t\(key)\nm_MetaKey\t\(metaData["MetaKey"]!)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\t\(String(InstanaSystemUtils.isDeviceJailbroken))\nsid\t\(sessionID.uuidString)\nti\t\(beacon.ti)\nue\t\(user.email ?? "")\nuf\tc\nui\t\(user.id)\nul\ten\nun\t\(user.name ?? "")\nv\t\(viewName!)\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        AssertEqualAndNotNil(sut, expected)
    }

    // MARK: Extension
    func test_wifi_5g_Beacon_asString_Default() {
        // Given
        let beacon = wifiCoreBeacon!

        // When
        let sut = beacon.asString

        // Then
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncn\tNone\nct\twifi\ndma\tApple\ndmo\t\(beacon.dmo)\nect\t5g\nk\t\(key)\nm_MetaKey\t\(metaData["MetaKey"]!)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\t\(String(InstanaSystemUtils.isDeviceJailbroken))\nsid\t\(sessionID.uuidString)\nti\t\(beacon.ti)\nue\t\(user.email ?? "")\nuf\tc\nui\t\(user.id)\nul\ten\nun\t\(user.name ?? "")\nusi\t\(beacon.usi!)\nv\t\(viewName!)\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        AssertEqualAndNotNil(sut, expected)
        AssertEqualAndNotNil(beacon.ct, "wifi")
        AssertEqualAndNotNil(beacon.ect, "5g")
    }

    func test_asJSON() {
        // Given
        let beacon = coreBeacon!

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
        let beacon = coreBeacon!
        let value = beacon.ab

        // When
        let sut = beacon.formattedKVPair(key: "ab", value: value)

        // When
        XCTAssertEqual(sut, "ab\t\(value)")
    }

    func test_formattedKVPair_nil_value() {
        // Given
        let beacon = coreBeacon!
        let value = Optional<Any>.none as Any

        // When
        let sut = beacon.formattedKVPair(key: "KEY", value: value)

        // When
        XCTAssertNil(sut)
    }

    func test_formattedKVPair_empty_value() {
        // Given
        let beacon = coreBeacon!
        let value = ""

        // When
        let sut = beacon.formattedKVPair(key: "KEY", value: value)

        // When
        XCTAssertNil(sut)
    }

    func test_cleaning() {
        // Given
        coreBeacon.bt = """
        \t
        Trace ab
        """

        // When
        let sut = coreBeacon.formattedKVPair(key: "bt", value: coreBeacon.bt!)

        // Then
        XCTAssertEqual(coreBeacon.bt, "\t\nTrace ab")
        XCTAssertEqual(sut, "bt\tTrace ab")
    }

    func test_format_clean_meta() {
        // Given
        coreBeacon.m = ["Key": "Some\nNewline\tTab\\escape", "More": "\ntest\n"]

        // When
        let sut = coreBeacon.formattedKVPair(key: "m", value: coreBeacon.m!)

        // Then
        let valid1 = "m_Key\tSome\\nNewline\\tTab\\\\escape\nm_More\ttest"
        let valid2 = "m_More\ttest\nm_Key\tSome\\nNewline\\tTab\\\\escape"
        let isValid = sut == valid1 || sut == valid2
        AssertTrue(isValid)
    }

    func test_format_empty_meta_value() {
        // Given
        coreBeacon.m = ["Key": "Some\nNewline\tTab\\escape", "More": ""]

        // When
        let sut = coreBeacon.formattedKVPair(key: "m", value: coreBeacon.m!)

        // Then
        AssertEqualAndNotNil(sut, "m_Key\tSome\\nNewline\\tTab\\\\escape")
    }

    func test_truncate_at_max_length() {
        // Given
        let longString = (0...CoreBeacon.maxLengthPerField).map {"\($0)"}.joined()
        var beacon = coreBeacon!
        beacon.bt = longString

        // When
        let sut = coreBeacon.formattedKVPair(key: "bt", value: beacon.bt!)

        // Then
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut!.hasSuffix("…"))
        XCTAssertEqual(CoreBeacon.maxLengthPerField, 16384)
    }

    func test_getInstanaAgentVersion() {
        let sut = CoreBeacon.getInstanaAgentVersion(hybridAgentId: nil, hybridAgentVersion: nil)
        let expected = "\(InstanaSystemUtils.agentVersion)"
        XCTAssertEqual(sut, expected)

        let sutFlutter = CoreBeacon.getInstanaAgentVersion(hybridAgentId: "f", hybridAgentVersion: "3.0.6")
        let expectedFlutter = "\(InstanaSystemUtils.agentVersion):f:3.0.6"
        XCTAssertEqual(sutFlutter, expectedFlutter)

        let sutRn = CoreBeacon.getInstanaAgentVersion(hybridAgentId: "r", hybridAgentVersion: "2.0.3")
        let expectedRn = "\(InstanaSystemUtils.agentVersion):r:2.0.3"
        XCTAssertEqual(sutRn, expectedRn)

        // negative cases
        let sutMisConfigVer = CoreBeacon.getInstanaAgentVersion(hybridAgentId: nil, hybridAgentVersion: "misConfigedVersion")
        let expectedMisConfigVer = "\(InstanaSystemUtils.agentVersion)"
        XCTAssertEqual(sutMisConfigVer, expectedMisConfigVer)

        let sutMisConfigId = CoreBeacon.getInstanaAgentVersion(hybridAgentId: "misConfigedId", hybridAgentVersion: nil)
        let expectedMisConfigId = "\(InstanaSystemUtils.agentVersion)"
        XCTAssertEqual(sutMisConfigId, expectedMisConfigId)

        let sutMisConfigEmpty = CoreBeacon.getInstanaAgentVersion(hybridAgentId: "", hybridAgentVersion: " ")
        let expectedMisConfigEmpty = "\(InstanaSystemUtils.agentVersion)"
        XCTAssertEqual(sutMisConfigEmpty, expectedMisConfigEmpty)
    }
}
