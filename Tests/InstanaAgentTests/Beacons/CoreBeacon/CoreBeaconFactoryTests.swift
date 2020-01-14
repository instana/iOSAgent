import Foundation
import XCTest
import UIKit
@testable import InstanaAgent

class CoreBeaconFactoryTests: InstanaTestCase {

    var randomViewName: String { "Details \((0...9999).randomElement() ?? 1)" }

    func test_undefined_beacon_type() {
        // Given
        let beacon = Beacon()
        let factory = CoreBeaconFactory(InstanaEnvironment.mock)

        // When
        XCTAssertThrowsError(try factory.map(beacon)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
    }

    func test_map_beacon() {
        // Given
        let sessionID = UUID()
        let timestamp = Date().millisecondsSince1970
        let viewName = randomViewName
        let beacon = ViewChange(timestamp: timestamp, sessionID: sessionID, viewName: viewName)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .viewChange)
        AssertEqualAndNotNil(sut.v, viewName)
        AssertEqualAndNotNil(sut.k, key)
        AssertEqualAndNotNil(sut.ti, "\(beacon.timestamp)")
        AssertEqualAndNotNil(sut.sid, "\(beacon.sessionID)")
        AssertEqualAndNotNil(sut.bid, "\(beacon.id)")
        AssertEqualAndNotNil(sut.buid, "\(InstanaSystemUtils.applicationBundleIdentifier)")
        AssertEqualAndNotNil(sut.ul, "en")
        AssertEqualAndNotNil(sut.ab, "\(InstanaSystemUtils.applicationBuildNumber)")
        AssertEqualAndNotNil(sut.av, "\(InstanaSystemUtils.applicationVersion)")
        AssertEqualAndNotNil(sut.osn, "\(InstanaSystemUtils.systemName)")
        AssertEqualAndNotNil(sut.osv, "\(InstanaSystemUtils.systemVersion)")
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.dmo, "\(InstanaSystemUtils.deviceModel)")
        AssertEqualAndNotNil(sut.ro, "false")
        AssertEqualAndNotNil(sut.vw, "\(Int(InstanaSystemUtils.screenSize.width))")
        AssertEqualAndNotNil(sut.vh, "\(Int(InstanaSystemUtils.screenSize.height))")
        AssertEqualAndNotNil(sut.cn, "\(InstanaSystemUtils.networkUtility.connectionType.cellular.carrierName)")
        AssertEqualAndNotNil(sut.ct, "\(InstanaSystemUtils.networkUtility.connectionType.description)")

        AssertTrue(sut.ec == nil)
        AssertTrue(sut.et == nil)
        AssertTrue(sut.em == nil)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 19)
    }

    func test_map_beacon_implicit_values() {
        // Given
        let viewName = randomViewName
        Instana.current?.environment.propertyHandler.properties.view = viewName
        let beacon = ViewChange()
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.v, viewName)
        AssertEqualAndNotNil(sut.ti, "\(beacon.timestamp)")
        AssertEqualAndNotNil(sut.bid, "\(beacon.id)")
    }

    func test_map_http_in_background_overriding_viewName() {
        // Given
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        let viewName = randomViewName
        let timestamp = Date().millisecondsSince1970
        let beacon = ViewChange(timestamp: timestamp, sessionID: UUID(), viewName: viewName)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.v, "Background")
    }

    func test_create_from_string() {
        // Given
        let httpBody = "ab\t15702\nav\tunknown-version\nbid\tB5FAF31C-FE37-482E-97F2-20D49C506586\nbt\tBackendTracingID\nbuid\tcom.apple.dt.xctest.tool\ncn\tNone\nct\tUnknown\nd\t1578569955952\ndma\tApple\ndmo\tx86_64\nec\t1\nem\tA client or server connection was severed in the middle of an in-progress load.\net\tNetwork Connection Lost\nhm\tPOST\nhs\t200\nhu\thttps://www.example.com\nk\tKEY\nosn\tiOS\nosv\t13.3\nro\tfalse\nsid\t70BED140-D947-4EC7-ADE9-8F1F7C6955D0\nt\thttpRequest\nti\t1578569955952\nul\ten\nvh\t1792\nvw\t828"

        // When
        let sut = try? CoreBeacon.create(from: httpBody)

        // Then
        AssertEqualAndNotNil(sut?.t, BeaconType.httpRequest)
        AssertEqualAndNotNil(sut?.ab, "15702")
        AssertEqualAndNotNil(sut?.av, "unknown-version")
        AssertEqualAndNotNil(sut?.bid, "B5FAF31C-FE37-482E-97F2-20D49C506586")
        AssertEqualAndNotNil(sut?.bt, "BackendTracingID")
        AssertEqualAndNotNil(sut?.buid, "com.apple.dt.xctest.tool")
        AssertEqualAndNotNil(sut?.cn, "None")
        AssertEqualAndNotNil(sut?.ct, "Unknown")
        AssertEqualAndNotNil(sut?.d, "1578569955952")
        AssertEqualAndNotNil(sut?.dma, "Apple")
        AssertEqualAndNotNil(sut?.dmo, "x86_64")
        AssertEqualAndNotNil(sut?.ec, "1")
        AssertEqualAndNotNil(sut?.et, "Network Connection Lost")
        AssertEqualAndNotNil(sut?.em, "A client or server connection was severed in the middle of an in-progress load.")
        AssertEqualAndNotNil(sut?.hm, "POST")
        AssertEqualAndNotNil(sut?.hs, "200")
        AssertEqualAndNotNil(sut?.hu, "https://www.example.com")
        AssertEqualAndNotNil(sut?.k, "KEY")
        AssertEqualAndNotNil(sut?.osn, "iOS")
        AssertEqualAndNotNil(sut?.osv, "13.3")
        AssertEqualAndNotNil(sut?.ro, "false")
        AssertEqualAndNotNil(sut?.sid, "70BED140-D947-4EC7-ADE9-8F1F7C6955D0")
        AssertEqualAndNotNil(sut?.ti, "1578569955952")
        AssertEqualAndNotNil(sut?.ul, "en")
        AssertEqualAndNotNil(sut?.vh, "1792")
        AssertEqualAndNotNil(sut?.vw, "828")

        let mirror = Mirror(reflecting: sut!)
        AssertEqualAndNotZero(mirror.nonNilChildren.count, 26)
    }

    /// All other beacon mapping will be tested in the 'Beacon Types' Tests (i.e. HTTPBeaconTests)
}
