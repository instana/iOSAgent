import Foundation
import XCTest
@testable import InstanaAgent

class ReporterIntegrationTests: InstanaTestCase {

    var networkUtil: NetworkUtility!
    var reporter: Reporter!

    override func setUp() {
        super.setUp()
        var config = InstanaConfiguration.mock(key: "KEY")
        config.reportingURL = .random
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        config.gzipReport = false
        session = InstanaSession.mock(configuration: config)
    }

    ////
    /// Simple test to flushing queue and verify transmitted beacons to webserver
    func test_report_http_happy_path() {
        // Given
        networkUtil = NetworkUtility.wifi
        InstanaSystemUtils.networkUtility = networkUtil

        let submittingBeacon = HTTPBeacon.createMock()
        submittingBeacon.backendTracingID = "backendTraceID"
        let expectedBeacon = try? CoreBeaconFactory(session).map(submittingBeacon)
        let waitFor = expectation(description: "Wait For")
        var sentBeaconData: Data?

        reporter = Reporter(session, networkUtility: networkUtil) {request, completion   in
            sentBeaconData = request.httpBody
            completion(.success(statusCode: 200))
        }

        // When
        reporter.submit(submittingBeacon)
        reporter.completionHandler.append {_ in
            DispatchQueue.main.async {
                waitFor.fulfill()
            }
        }

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(reporter.queue.items.isEmpty)

        // Then verify the sent beacon body in the URLRequest going out to the server
        let serverReceivedHTTP = String(data: sentBeaconData ?? Data(), encoding: .utf8)
        do {
            let serverBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
            AssertEqualAndNotNil(serverBeacon.em, "Network Connection Lost: A client or server connection was severed in the middle of an in-progress load.")
            AssertEqualAndNotNil(serverBeacon.ec, "1")
            AssertEqualAndNotNil(serverBeacon.et, "HTTPError")
            AssertEqualAndNotNil(serverBeacon.bt, "backendTraceID")
            AssertEqualAndNotNil(serverBeacon.hm, "POST")
            AssertEqualAndNotNil(serverBeacon.hs, "200")
            AssertEqualAndNotNil(serverBeacon.hu, "https://www.example.com")
            AssertTrue(serverBeacon.hp == nil)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }

    //
    func test_report_offline_and_online() {
        // Given
        networkUtil = NetworkUtility.none
        InstanaSystemUtils.networkUtility = networkUtil
        var flushCount = 0
        var sentBeaconData: Data?
        let submittingBeacon = HTTPBeacon.createMock()
        let expectedBeacon = try? CoreBeaconFactory(session).map(submittingBeacon)
        let waitForFirstFlushTry = expectation(description: "Wait For First Flush")
        let waitForSecondFlushTry = expectation(description: "Wait For Second Flush")
        var resultError: InstanaError?

        reporter = Reporter(session, networkUtility: networkUtil) {request, completion   in
            sentBeaconData = request.httpBody
            completion(.success(statusCode: 200))
        }

        // When
        reporter.submit(submittingBeacon)
        reporter.completionHandler.append {beaconResult in
            DispatchQueue.main.async {
                flushCount += 1
                resultError = beaconResult.error as? InstanaError
                switch flushCount {
                case 1: waitForFirstFlushTry.fulfill()
                case 2: waitForSecondFlushTry.fulfill()
                default: break
                }
            }
        }

        // Then
        wait(for: [waitForFirstFlushTry], timeout: 5.0)
        AssertEqualAndNotZero(reporter.queue.items.count, 1)
        AssertTrue(resultError?.code == InstanaError.Code.offline.rawValue)

        // When going online again
        networkUtil.update(.wifi)

        // Then - expect a successful flush
        wait(for: [waitForSecondFlushTry], timeout: 10.0)
        AssertTrue(reporter.queue.items.isEmpty)

        // Then verify the sent beacon body in the URLRequest going out to the server
        let serverReceivedHTTP = String(data: sentBeaconData ?? Data(), encoding: .utf8)
        do {
            let serverBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }
}
