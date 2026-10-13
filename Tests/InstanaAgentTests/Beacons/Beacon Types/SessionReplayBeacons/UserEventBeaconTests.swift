
import XCTest
@_spi(Internal) @testable import InstanaAgent

class UserEventBeaconTests: InstanaTestCase {

    // MARK: - Initializer tests

    func test_init() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "testUserEventType"
        let viewClassName = "testViewClassName"
        let viewId = "testViewId"

        // When
        let sut = UserEventBeacon(timestamp: ti, eventType: eventType, viewClassName: viewClassName, viewId: viewId)

        // Then
        XCTAssertEqual(ti, sut.timestamp)
        XCTAssertEqual(eventType, sut.eventType)
        XCTAssertEqual(viewClassName, sut.viewClassName)
        XCTAssertEqual(viewId, sut.viewId)
    }

    func test_init_defaultOptionals() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "tap"

        // When — only required params supplied
        let sut = UserEventBeacon(timestamp: ti, eventType: eventType)

        // Then — all optional fields should be nil / empty
        XCTAssertEqual(ti, sut.timestamp)
        XCTAssertEqual(eventType, sut.eventType)
        XCTAssertNil(sut.eventValue)
        XCTAssertNil(sut.viewClassName)
        XCTAssertNil(sut.viewId)
    }

    func test_init_withEventValue() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "input"
        let eventValue = "some text"

        // When
        let sut = UserEventBeacon(timestamp: ti, eventType: eventType, eventValue: eventValue)

        // Then
        XCTAssertEqual(eventType, sut.eventType)
        XCTAssertEqual(eventValue, sut.eventValue)
    }

    // MARK: - description property

    func test_description_allFields() {
        // Given
        let sut = UserEventBeacon(timestamp: 1000, eventType: "tp", eventValue: "loginBtn",
                                  viewClassName: "UIButton", viewId: "btn_login_id")

        // When
        let desc = sut.description

        // Then
        XCTAssertTrue(desc.contains("eventType:tp"))
        XCTAssertTrue(desc.contains("eventValue:loginBtn"))
        XCTAssertTrue(desc.contains("viewClassName:UIButton"))
        XCTAssertTrue(desc.contains("viewId=btn_login"))
    }

    func test_description_nilOptionals() {
        // Given
        let sut = UserEventBeacon(timestamp: 1000, eventType: "tp")

        // When
        let desc = sut.description

        // Then
        XCTAssertTrue(desc.contains("eventValue:nil"))
    }

    // MARK: - Codable round-trip (encode / decode)

    func test_codable_roundTrip_fullFields() throws {
        // Given
        let ti: Instana.Types.Milliseconds = 1_700_000_000_000
        let viewId = "btn_ok_id"
        let original = UserEventBeacon(timestamp: ti, eventType: "tp", viewClassName: "UIButton", viewId: viewId)

        // When — encode then decode
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserEventBeacon.self, from: encoded)

        // Then
        XCTAssertEqual(decoded.timestamp, ti)
        XCTAssertEqual(decoded.eventType, "tp")
        XCTAssertEqual(decoded.viewClassName, "UIButton")
        XCTAssertEqual(decoded.viewId, viewId)
    }

    func test_codable_roundTrip_nilOptionals() throws {
        // Given — coordinates is empty, optionals are nil
        let ti: Instana.Types.Milliseconds = 1_700_000_000_000
        let original = UserEventBeacon(timestamp: ti, eventType: "scroll")

        // When — encode then decode
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserEventBeacon.self, from: encoded)

        // Then — empty coordinates should remain empty after round-trip
        XCTAssertEqual(decoded.timestamp, ti)
        XCTAssertEqual(decoded.eventType, "scroll")
        XCTAssertNil(decoded.eventValue)
        XCTAssertNil(decoded.viewClassName)
        XCTAssertNil(decoded.viewId)
    }

    func test_encode_coordinatesOmittedWhenEmpty() throws {
        // Given
        let sut = UserEventBeacon(timestamp: 1000, eventType: "tp")

        // When
        let encoded = try JSONEncoder().encode(sut)
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]

        // Then — "coords" key must be absent when coordinates array is empty
        XCTAssertNil(json["coords"])
    }

    // MARK: - CoreBeaconFactory / asString tests

    func test_asString() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "evtTypeValue"
        let viewClassName = "testViewClassName"
        let viewId = "testViewId"

        // When
        let userEventBeacon = UserEventBeacon(timestamp: ti, eventType: eventType,
                                              viewClassName: viewClassName, viewId: viewId)

        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(userEventBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then
        AssertTrue(userEventBeacon.viewName == nil)
        AssertEqualAndNotNil(beacon.v, nil)

        let expected = "bid\t\(beacon.bid)\nevt\t\(userEventBeacon.eventType)\nk\tKEY\nsid\t\(beacon.sid)\nsrv\t\(VersionConfig.sessionReplayVersion)\nt\tued\nti\t\(userEventBeacon.timestamp)\nvi\t\(userEventBeacon.viewId!)\nvn\t\(userEventBeacon.viewClassName!)"
        AssertEqualAndNotNil(sut, expected)
    }

    func test_asString_withViewClassName() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "tp"
        let viewClassName1 = "testViewClassName1"
        let userEventBeacon = UserEventBeacon(timestamp: ti, eventType: eventType, viewClassName: viewClassName1)

        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(userEventBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then — the evv dict is formatted as "<eventType>\t<eventValue>"
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut!.contains("evt\t\(eventType)"))
        XCTAssertTrue(sut!.contains("vn\t\(viewClassName1)"))
    }

    func test_asString_minimalBeacon_noOptionals() {
        // Given — no coordinates, no viewClassName, no viewId, no eventValue
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let eventType = "fake"
        let userEventBeacon = UserEventBeacon(timestamp: ti, eventType: eventType)

        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(userEventBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then — mandatory fields present, optional fields absent
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut!.contains("evt\t\(eventType)"))
        XCTAssertTrue(sut!.contains("t\tued"))
        XCTAssertFalse(sut!.contains("vn\t"), "viewClassName should be absent when nil")
        XCTAssertFalse(sut!.contains("vi\t"), "viewId should be absent when nil")
    }

    func test_coreBeacon_fields_clearedForUed() {
        // Given
        let ti: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let viewId = "btn-id"
        let userEventBeacon = UserEventBeacon(timestamp: ti, eventType: "tp", viewClassName: "UIButton", viewId: viewId)

        // When
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(userEventBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // Then — fields that must be nil for ued beacons per CoreBeaconFactory.append
        XCTAssertNil(beacon.v,   "View Name should be nil for ued")
        XCTAssertNil(beacon.sr,  "Session Replay status should be nil for ued")
        XCTAssertNil(beacon.bt,  "Backend Tracing ID should be nil for ued")
        XCTAssertNil(beacon.usi, "User Session ID should be nil for ued")
        XCTAssertNil(beacon.uf,  "Mobile Feature list should be nil for ued")
        XCTAssertNil(beacon.bi,  "Bundle ID should be nil for ued")
        XCTAssertNil(beacon.m,   "MetaData should be nil for ued")
        XCTAssertNil(beacon.ui,  "User ID should be nil for ued")
        XCTAssertNil(beacon.un,  "User Name should be nil for ued")
        XCTAssertNil(beacon.ue,  "User email should be nil for ued")

        // And mandatory ued fields must be set
        XCTAssertEqual(beacon.t, .ued)
        XCTAssertEqual(beacon.srv, VersionConfig.sessionReplayVersion)
        XCTAssertEqual(beacon.evt, "tp")
        XCTAssertEqual(beacon.vn, "UIButton")
        XCTAssertEqual(beacon.vi, viewId)
    }
}
