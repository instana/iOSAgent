
import XCTest
@testable import InstanaAgent

class HTTPBeaconTests: InstanaTestCase {

    func test_map_http_no_error() {
        // Given
        let responseSize = HTTPMarker.Size(header: 4, body: 5, bodyAfterDecoding: 6)
        let url = URL.random
        let method = "POST"
        let backendTracingID = "BackendTID"
        let timestamp = Date().millisecondsSince1970
        let http = HTTPBeacon(timestamp: timestamp,
                                method: method,
                                url: url,
                                responseCode: 200,
                                responseSize: responseSize,
                                backendTracingID: backendTracingID,
                                viewName: "View Details")
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(http) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.v, "View Details")
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.bt, backendTracingID)
        AssertEqualAndNotNil(sut.hu, url.absoluteString)
        AssertEqualAndNotNil(sut.hp, url.path)
        AssertEqualAndNotNil(sut.hs, String(http.responseCode))
        AssertEqualAndNotNil(sut.hm, method)
        AssertEqualAndNotNil(sut.d, String(http.duration))
        AssertEqualAndNotNil(sut.ebs, String(responseSize.bodyBytes!))
        AssertEqualAndNotNil(sut.trs, String(responseSize.headerBytes! + responseSize.bodyBytes!))
        AssertEqualAndNotNil(sut.dbs, String(responseSize.bodyBytesAfterDecoding!))
        AssertTrue(sut.ec == nil)
        AssertTrue(sut.et == nil)
        AssertTrue(sut.em == nil)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 30)
    }

    func test_map_http_with_error() {
        // Given
        let http = HTTPBeacon(timestamp: Date().millisecondsSince1970,
                                method: "POST",
                                url: URL.random,
                                responseCode: 0,
                                responseSize: HTTPMarker.Size(header: 4, body: 5, bodyAfterDecoding: 6),
                                error: timeout,
                                backendTracingID: "BackendTID",
                                viewName: "View")
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(http) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertTrue(sut.ec == "1")
        AssertTrue(sut.et == "HTTPError")
        AssertTrue(sut.em == "Timeout: An asynchronous operation timed out.")

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 33)
    }

    func test_map_http_with_code_399() {
        // Given
        let responseCode = 399
        let http = HTTPBeacon(timestamp: Date().millisecondsSince1970,
                                method: "POST",
                                url: URL.random,
                                responseCode: responseCode,
                                responseSize: HTTPMarker.Size.random)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(http) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .httpRequest)
        AssertEqualAndNotNil(sut.hs, String(responseCode))
        AssertTrue(sut.ec == nil)
    }

    func test_map_http_with_error_since_400() {
        // The status code (between 400 and 599) overrides any error
        // Given
        let errorResponseCodes = (400...599)
        errorResponseCodes.forEach { code in
            let http = HTTPBeacon(timestamp: Date().millisecondsSince1970,
                                  method: "POST",
                                  url: URL.random,
                                  responseCode: code,
                                  responseSize: HTTPMarker.Size.random,
                                  error: timeout)
            let factory = CoreBeaconFactory(.mock)

            // When
            guard let sut = try? factory.map(http) else {
                XCTFail("Could not map Beacon to CoreBeacon")
                return
            }

            // Then
            AssertEqualAndNotNil(sut.t, .httpRequest)
            AssertEqualAndNotNil(sut.hs, String(code))
            AssertTrue(sut.ec == "1")
            AssertTrue(sut.et == "HTTPError")
            AssertTrue(sut.em == "HTTP \(code): HTTP Error with status code \(code)")
        }
    }

    func test_asString() {
        // Given
        let url: URL = .random
        let method = "POST"
        let responseCode = 200
        let responseSize = HTTPMarker.Size.random
        let timestamp: Instana.Types.Milliseconds = 1000
        let duration: Instana.Types.Milliseconds = 1
        let backendTracingID = "BackendTID"
        let viewName = "View"
        let http = HTTPBeacon(timestamp: timestamp, duration: duration, method: method, url: url, responseCode: responseCode, responseSize: responseSize, error: timeout, backendTracingID: backendTracingID, viewName: viewName)
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(http)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expectedErrorMessage = "\(HTTPError.timeout.rawValue): \(HTTPError.timeout.errorDescription)"
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\nbt\t\(backendTracingID)\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\nd\t\(duration)\ndbs\t\(responseSize.bodyBytesAfterDecoding!)\ndma\tApple\ndmo\t\(beacon.dmo)\nebs\t\(responseSize.bodyBytes!)\nec\t1\nem\t\(expectedErrorMessage)\net\tHTTPError\nhm\t\(method)\nhp\t\(url.path)\nhs\t\(responseCode)\nhu\t\(url.absoluteString)\nk\t\(key)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\tfalse\nsid\t\(beacon.sid)\nt\thttpRequest\nti\t\(timestamp)\ntrs\t\(responseSize.headerBytes! + responseSize.bodyBytes!)\nul\ten\nv\t\(viewName)\nvh\t\(Int(UIScreen.main.nativeBounds.height))\nvw\t\(Int(UIScreen.main.nativeBounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let responseSize = HTTPMarker.Size.random
        let backendTracingID = "BackendTID"
        let http = HTTPBeacon(timestamp: 1000, duration: 10, method: "M", url: URL.random, responseCode: 200, responseSize: responseSize, error: timeout, backendTracingID: backendTracingID)

        // When
        var beacon: CoreBeacon!
        do {
             beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(http)
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

    // MARK: Helper
    var timeout: NSError { NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil) }
}
