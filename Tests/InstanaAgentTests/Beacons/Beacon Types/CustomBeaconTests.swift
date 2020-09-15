import XCTest
@testable import InstanaAgent

class CustomBeaconTests: InstanaTestCase {

    func test_init_name() {
        // Given
        let name = "Test"

        // When
        let sut = CustomBeacon(name: name)

        // Then
        AssertEqualAndNotNil(sut.name, name)
        XCTAssertNil(sut.backendTracingID)
        AssertEqualAndNotNil(sut.viewName, CustomBeaconDefaultViewNameID)
        XCTAssertNil(sut.duration)
        XCTAssertNil(sut.metaData)
        XCTAssertNil(sut.error)
    }

    func test_init_name_and_viewname() {
        // Given
        let name = "Test"
        let viewName = "SomeView"

        // When
        let sut = CustomBeacon(name: name, viewName: viewName)

        // Then
        AssertEqualAndNotNil(sut.name, name)
        AssertEqualAndNotNil(sut.timestamp, Date().millisecondsSince1970)
        XCTAssertNil(sut.backendTracingID)
        AssertEqualAndNotNil(sut.viewName, viewName)
        XCTAssertNil(sut.duration)
        XCTAssertNil(sut.metaData)
        XCTAssertNil(sut.error)
    }

    func x_test_init_duration_given() {
        // Given
        let name = "Test"
        let duration: Instana.Types.Milliseconds = 12

        // When
        let sut = CustomBeacon(name: name, duration: duration)

        // Then
        AssertEqualAndNotNil(sut.name, name)
        AssertEqualAndNotNil(sut.timestamp, Date().millisecondsSince1970 - duration)
        AssertEqualAndNotNil(sut.duration, duration)
    }

    func test_init_duration_and_timestamp_given() {
        // Given
        let name = "Test"
        let duration: Instana.Types.Milliseconds = 12
        let timestamp: Instana.Types.Milliseconds = 12484

        // When
        let sut = CustomBeacon(timestamp: timestamp, name: name, duration: duration)

        // Then
        AssertEqualAndNotNil(sut.name, name)
        AssertEqualAndNotNil(sut.timestamp, timestamp)
        AssertEqualAndNotNil(sut.duration, duration)
    }

    func test_init_timestamp_given() {
        // Given
        let name = "Test"
        let timestamp: Instana.Types.Milliseconds = 12484

        // When
        let sut = CustomBeacon(timestamp: timestamp, name: name)

        // Then
        AssertEqualAndNotNil(sut.name, name)
        AssertEqualAndNotNil(sut.timestamp, timestamp)
        XCTAssertNil(sut.duration)
    }

    func test_full_asString() {
        // Given
        InstanaSystemUtils.networkUtility.update(.wifi)
        let customBeacon = createCustomBeacon()
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(customBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then
        XCTAssertNotNil(customBeacon.viewName)
        XCTAssertNotNil(customBeacon.duration)
        XCTAssertTrue(customBeacon.timestamp > 0)
        XCTAssertNotNil(customBeacon.metaData)
        XCTAssertNotNil(customBeacon.error)
        XCTAssertNotNil(customBeacon.backendTracingID)

        AssertEqualAndNotNil(beacon.v, customBeacon.viewName)
        AssertEqualAndNotNil(beacon.cen, customBeacon.name)
        AssertEqualAndNotNil(beacon.d, "\(customBeacon.duration ?? 0)")
        AssertEqualAndNotNil(beacon.ti, "\(customBeacon.timestamp)")
        AssertEqualAndNotNil(beacon.m, customBeacon.metaData)
        AssertEqualAndNotNil(beacon.bt, customBeacon.backendTracingID)
        AssertEqualAndNotNil(beacon.et, "\(type(of: customBeacon.error!))")
        AssertEqualAndNotNil(beacon.em, "\(customBeacon.error!)")
        AssertEqualAndNotNil(beacon.ec, "1")

        let expectediOSVersion = UIDevice.current.systemVersion
        let expectedErrorType = "\(type(of: customBeacon.error!))"
        let expectedErrorMessage = "\(customBeacon.error!)"
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\tunknown-version\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\nbt\t\(customBeacon.backendTracingID ?? "")\ncen\t\(customBeacon.name)\ncn\tNone\nct\t\(InstanaSystemUtils.networkUtility.connectionType.description)\nd\t\(customBeacon.duration ?? 0)\ndma\tApple\ndmo\tx86_64\nec\t1\nem\t\(expectedErrorMessage)\net\t\(expectedErrorType)\nk\tKEY\nm_\(customBeacon.metaData?.keys.first ?? "")\t\(customBeacon.metaData?.values.first ?? "")\nosn\tiOS\nosv\t\(expectediOSVersion)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\tcustom\nti\t\(customBeacon.timestamp)\nul\ten\nv\t\(customBeacon.viewName ?? "")\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        AssertEqualAndNotNil(sut, expected)
    }

    func test_asString_viewname_nil() {
        // Given
        InstanaSystemUtils.networkUtility.update(.cellular)
        let name = "SomeName"
        let session: InstanaSession = .mock(configuration: .mock)
        session.propertyHandler.properties.view = "SomeView"
        let customBeacon = CustomBeacon(name: name, viewName: nil)

        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(customBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then
        AssertTrue(customBeacon.viewName == nil)
        AssertEqualAndNotNil(beacon.v, nil)

        let expectediOSVersion = UIDevice.current.systemVersion
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\tunknown-version\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncen\t\(name)\ncn\tNone\nct\t\(InstanaSystemUtils.networkUtility.connectionType.description)\ndma\tApple\ndmo\tx86_64\nk\tKEY\nosn\tiOS\nosv\t\(expectediOSVersion)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\tcustom\nti\t\(customBeacon.timestamp)\nul\ten\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        AssertEqualAndNotNil(sut, expected)
    }

    func test_asString_viewname_implicit() {
        // Given
        InstanaSystemUtils.networkUtility.update(.none)
        let viewName = "ViewName"
        let name = "SomeName"
        let session: InstanaSession = .mock(configuration: .mock)

        session.propertyHandler.properties.view = viewName
        let customBeacon = CustomBeacon(name: name)

        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(session).map(customBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // Then
        AssertEqualAndNotNil(customBeacon.viewName, CustomBeaconDefaultViewNameID)
        AssertEqualAndNotNil(beacon.v, viewName)

        let expectediOSVersion = UIDevice.current.systemVersion
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\tunknown-version\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncen\t\(name)\ncn\tNone\nct\t\(InstanaSystemUtils.networkUtility.connectionType.description)\ndma\tApple\ndmo\tx86_64\nk\tKEY\nosn\tiOS\nosv\t\(expectediOSVersion)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\tcustom\nti\t\(customBeacon.timestamp)\nul\ten\nv\t\(viewName)\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        AssertEqualAndNotNil(sut, expected)
    }

    func test_asJSON() {
        // Given
        let customBeacon = createCustomBeacon()

        // When
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(customBeacon)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }
        let mirror = Mirror(reflecting: beacon!)
        guard let sut = beacon.asJSON else { XCTFail("Cannot convert Beacon to JSON"); return }

        // Then
        AssertTrue(sut.count > 0)
        AssertTrue(sut.count == mirror.nonNilChildren.count)

        mirror.nonNilChildren.forEach { child in
            if let value = child.value as? String {
                AssertEqualAndNotNil(sut[child.label] as? String, value, "Values for \(child.0) must be same")
            } else if let dict = child.value as? [String: String] {
                AssertEqualAndNotNil(sut[child.label] as? [String: String], dict, "Must be same")
            }
        }
    }

    // MARK: Helper
    enum SomeBeaconError: Error {
        case something
    }
    func createCustomBeacon() -> CustomBeacon {
        let viewName = "View Name"
        let timestamp: Instana.Types.Milliseconds = 12348
        let duration: Instana.Types.Milliseconds = 12
        let name = "SomeName"
        let backendTracingID = "BID"
        let error = SomeBeaconError.something
        let metaData = ["Key": "SomeValue"]
        return CustomBeacon(timestamp: timestamp, name: name, duration: duration, backendTracingID: backendTracingID, error: error, metaData: metaData, viewName: viewName)
    }
}
