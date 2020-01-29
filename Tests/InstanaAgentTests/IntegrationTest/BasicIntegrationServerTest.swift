import Foundation
import XCTest
@testable import InstanaAgent

@available(iOS 12.0, *)
class BasicIntegrationServerTest: IntegrationTestCase {

    var session: InstanaSession!
    var networkUtil: NetworkUtility!
    var reporter: Reporter!

    override func setUp() {
        super.setUp()
        var config = InstanaConfiguration.mock(key: "KEY")
        config.reportingURL = Defaults.baseURL
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        config.gzipReport = false
        session = InstanaSession.mock(configuration: config)
    }

    ////
    /// Simple test to flushing queue and verify transmitted beacons to webserver
    func test_send() {
        // Given
        let submittingBeacon = HTTPBeacon.createMock()
        let waitFor = expectation(description: "Wait For")
        networkUtil = NetworkUtility.wifi
        reporter = Reporter(session, networkUtility: networkUtil)

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


        // Then Verify the server response - server must received same as we sent
        let serverReceivedHTTP = String(data: serverReceivedBody.last ?? Data(), encoding: .utf8)
        do {
            let serverBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }

    //
    func test_be_offline_and_online() {
        // Given
        var flushCount = 0
        let submittingBeacon = HTTPBeacon.createMock()
        let waitForFirstFlushTry = expectation(description: "Wait For First Flush")
        let waitForSecondFlushTry = expectation(description: "Wait For Second Flush")
        var resultError: InstanaError?
        networkUtil = NetworkUtility.none
        reporter = Reporter(session, networkUtility: networkUtil)

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

        // Then Verify the server response - must be the same as we sent
        let serverReceivedHTTP = String(data: serverReceivedBody.last ?? Data(), encoding: .utf8)
        do {
            let serverBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }
}
