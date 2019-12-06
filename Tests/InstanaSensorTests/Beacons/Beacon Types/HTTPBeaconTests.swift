
import XCTest
@testable import InstanaSensor

class HTTPBeaconTests: XCTestCase {

    func test_map_http() {
        // Given
        let config = InstanaConfiguration.default(key: "KEY")
        let url = URL.random
        let method = "POST"
        let timestamp = Date().millisecondsSince1970
        let http = HTTPBeacon(timestamp: timestamp,
                                method: method,
                                url: url,
                                connectionType: .wifi,
                                result: "RESULT")
        let mapper = CoreBeaconFactory(config)

        // When
        guard let sut = try? mapper.map(http) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.hu, url.absoluteString)
        AssertEqualAndNotNil(sut.hp, url.path)
        AssertEqualAndNotNil(sut.hs, String(http.responseCode))
        AssertEqualAndNotNil(sut.hm, method)
        AssertEqualAndNotNil(sut.trs, String(http.responseSize))
        AssertEqualAndNotNil(sut.d, String(http.duration))

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 24)
    }

    func test_asString() {
        // Given
        let url: URL = .random
        let key = "K1234"
        let method = "POST"
        let responseCode = 200
        let requestSize: Instana.Types.Bytes = 1024
        let responseSize: Instana.Types.Bytes = 512
        let timestamp: Instana.Types.Milliseconds = 1000
        let duration: Instana.Types.Milliseconds = 1
        let http = HTTPBeacon(timestamp: timestamp, duration: duration, method: method, url: url, connectionType: .cellular, responseCode: responseCode, requestSize: requestSize, responseSize: responseSize, result: "R")
        var beacon: CoreBeacon!
        do {
             beacon = try CoreBeaconFactory(InstanaConfiguration.default(key: key)).map(http)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nav\t\(beacon.av)\nbid\t\(beacon.bid)\nbuid\t\(beacon.buid)\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\nd\t\(duration)\ndma\tApple\ndmo\t\(beacon.dmo)\nhm\t\(method)\nhp\t\(url.path)\nhs\t\(responseCode)\nhu\t\(url.absoluteString)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\nro\tfalse\nsid\t\(beacon.sid)\nt\thttpRequest\nti\t\(timestamp)\ntrs\t\(responseSize)\nul\ten\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let key = "123KEY"
        let http = HTTPBeacon(timestamp: 1000, duration: 10, method: "M", url: URL.random, connectionType: .cellular, responseCode: 200, requestSize: 512, responseSize: 64, result: "R")

        // When
        var beacon: CoreBeacon!
        do {
             beacon = try CoreBeaconFactory(InstanaConfiguration.default(key: key)).map(http)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }
        let mirror = Mirror(reflecting: beacon!)
        guard let sut = beacon.asJSON else { XCTFail("Cannot convert Beacon to JSON"); return }

        // Then
        AssertTrue(sut.count > 0)
        AssertTrue(sut.count == mirror.nonNilChildren.count)

        mirror.nonNilChildren.forEach { child in
            let value = child.value as AnyObject
            AssertEqualAndNotNil(sut[child.label] as? String, value.description, "Values for \(child.0) must be same")
        }
    }
}
