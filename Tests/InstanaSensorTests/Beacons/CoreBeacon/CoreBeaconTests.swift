
import XCTest
@testable import InstanaSensor

class CoreBeaconTests: XCTestCase {

    func test_create_default() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let sut = CoreBeacon.createDefault(key: "KEY123", timestamp: timestamp, sessionId: "SID", id: "EID")

        // Then
        AssertEqualAndNotNil(sut.k, "KEY123")
        AssertEqualAndNotNil(sut.ti, String(timestamp))
        AssertEqualAndNotNil(sut.sid, "SID")
        AssertEqualAndNotNil(sut.bid, "EID")
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
    }

    func testNumberOfFields_all() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")

        // When
        let values = Mirror(reflecting: sut).children

        // Then
        XCTAssertEqual(values.count, 34)
    }

    func testNumberOfFields_non_nil() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")

        // When
        let values = Array(Mirror(reflecting: sut).nonNilChildren)

        // Then
        XCTAssertEqual(values.count, 17)
    }


    func test_all_keys() {
        // Given
        let sut = CoreBeacon.createDefault(key: "KEY123")
        // TODO: Add all keys of Beacon
        let expectedKeys = ["t", "bt", "k"]
    
        // When
        let keys = Mirror(reflecting: sut).children.compactMap {$0.label}

        // Then
        let matchingKeys = expectedKeys.filter {key in
            keys.contains(key)
        }

        XCTAssertEqual(expectedKeys.count, matchingKeys.count)
    }
}
