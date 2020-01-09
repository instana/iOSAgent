import Foundation
import XCTest
@testable import InstanaAgent

class CoreBeaconFactoryTests: XCTestCase {

    var config: InstanaConfiguration!

    override func setUp() {
        super.setUp()
        config = InstanaConfiguration.default(key: "KEY")
    }

    func test_undefined_beacon_type() {
        // Given
        let beacon = Beacon()
        let mapper = CoreBeaconFactory(InstanaEnvironment.mock)

        // When
        XCTAssertThrowsError(try mapper.map(beacon)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
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
