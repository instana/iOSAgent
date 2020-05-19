import XCTest
@testable import InstanaAgent

class CustomBeaconTests: InstanaTestCase {

    func test_init_name() {
        // Given
        let name = "Test"

        // When
        let sut = CustomBeacon(name: name)

        // Then
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.timestamp, Date().millisecondsSince1970)
        XCTAssertNil(sut.backendTracingID)
        XCTAssertNil(sut.viewName)
        XCTAssertNil(sut.duration)
        XCTAssertNil(sut.meta)
        XCTAssertNil(sut.error)
    }

    func test_init_duration_given() {
        // Given
        let name = "Test"
        let duration: Instana.Types.Milliseconds = 12

        // When
        let sut = CustomBeacon(name: name, duration: duration)

        // Then
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.timestamp, Date().millisecondsSince1970 - duration)
        XCTAssertEqual(sut.duration, duration)
    }

    func test_init_duration_and_timestamp_given() {
        // Given
        let name = "Test"
        let duration: Instana.Types.Milliseconds = 12
        let timestamp: Instana.Types.Milliseconds = 12484

        // When
        let sut = CustomBeacon(timestamp: timestamp, name: name, duration: duration)

        // Then
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.timestamp, timestamp)
        XCTAssertEqual(sut.duration, duration)
    }

    func test_init_timestamp_given() {
        // Given
        let name = "Test"
        let timestamp: Instana.Types.Milliseconds = 12484

        // When
        let sut = CustomBeacon(timestamp: timestamp, name: name)

        // Then
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.timestamp, timestamp)
        XCTAssertNil(sut.duration)
    }

    func test_asString() {
        // Given
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
        XCTAssertNotNil(customBeacon.meta)
        XCTAssertNotNil(customBeacon.error)
        XCTAssertNotNil(customBeacon.backendTracingID)

        XCTAssertEqual(beacon.v, customBeacon.viewName)
        XCTAssertEqual(beacon.cen, customBeacon.name)
        XCTAssertEqual(beacon.d, "\(customBeacon.duration ?? 0)")
        XCTAssertEqual(beacon.ti, "\(customBeacon.timestamp)")
        XCTAssertEqual(beacon.m, customBeacon.meta)
        XCTAssertEqual(beacon.bt, customBeacon.backendTracingID)
        XCTAssertEqual(beacon.et, "\(type(of: customBeacon.error!))")
        XCTAssertEqual(beacon.em, "\(customBeacon.error!)")
        XCTAssertEqual(beacon.ec, "1")

        let expectediOSVersion = UIDevice.current.systemVersion
        let expectedErrorType = "\(type(of: customBeacon.error!))"
        let expectedErrorMessage = "\(customBeacon.error!)"
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\tunknown-version\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\nbt\t\(customBeacon.backendTracingID ?? "")\ncen\t\(customBeacon.name)\ncn\tNone\nct\tUnknown\nd\t\(customBeacon.duration ?? 0)\ndma\tApple\ndmo\tx86_64\nec\t1\nem\t\(expectedErrorMessage)\net\t\(expectedErrorType)\nk\tKEY\nm_\(customBeacon.meta?.keys.first ?? "")\t\(customBeacon.meta?.values.first ?? "")\nosn\tiOS\nosv\t\(expectediOSVersion)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\tcustom\nti\t\(customBeacon.timestamp)\nul\ten\nv\t\(customBeacon.viewName ?? "")\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
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
        let timestamp: Instana.Types.Milliseconds = 12348
        let duration: Instana.Types.Milliseconds = 12
        let name = "SomeName"
        let backendTracingID = "BID"
        let error = SomeBeaconError.something
        let meta = ["Key":"SomeValue"]
        let viewName = "The View Name"
        return CustomBeacon(timestamp: timestamp, name: name, duration: duration, backendTracingID: backendTracingID, error: error, meta: meta, viewName: viewName)
    }
}
