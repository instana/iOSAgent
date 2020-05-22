import Foundation
import XCTest
@testable import InstanaAgent

class ReporterIntegrationTests: InstanaTestCase {

    var session: InstanaSession!
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
        let submittingBeacon = HTTPBeacon.createMock()
        let waitFor = expectation(description: "Wait For")
        var sentBeaconData: Data?
        networkUtil = NetworkUtility.wifi
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
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }

    //
    func test_report_offline_and_online() {
        // Given
        var flushCount = 0
        var sentBeaconData: Data?
        let submittingBeacon = HTTPBeacon.createMock()
        let waitForFirstFlushTry = expectation(description: "Wait For First Flush")
        let waitForSecondFlushTry = expectation(description: "Wait For Second Flush")
        var resultError: InstanaError?
        networkUtil = NetworkUtility.none
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
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }

    func test_report_custom_event() {
        // Given
        let timestamp: Int64 = 1234
        let name = "Some name"
        let duration: Int64 = 12
        let backendTracingID = "BackendID"
        let error: NSError = InstanaError(code: .invalidResponse, description: "Some")
        let mKey = "Key"
        let mValue = "Value"
        let viewName = "View"
        let submittingBeacon = CustomBeacon(timestamp: timestamp, name: name, duration: duration, backendTracingID: backendTracingID, error: error, meta: [mKey: mValue], viewName: viewName)
        let waitFor = expectation(description: "Wait For")
        var sentBeaconData: Data?
        reporter = Reporter(session, networkUtility: .wifi) {request, completion   in
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
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
            AssertEqualAndNotNil(serverBeacon.v, viewName)
            AssertEqualAndNotNil(serverBeacon.bt, backendTracingID)
            AssertEqualAndNotNil(serverBeacon.ti, "\(timestamp)")
            AssertEqualAndNotNil(serverBeacon.d, "\(duration)")
            AssertEqualAndNotNil(serverBeacon.cen, name)
            AssertEqualAndNotNil(serverBeacon.ec, "\(1)")
            AssertEqualAndNotNil(serverBeacon.et, "InstanaError")
            AssertEqualAndNotNil(serverBeacon.em, "Error Domain=com.instana.ios.agent.error Code=2 \"Some\" UserInfo={NSLocalizedDescription=Some}")
            AssertEqualAndNotNil(serverBeacon.m?[mKey], mValue)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }

    func test_report_custom_event_current_viewName() {
        // Given
        let name = "Some name"
        let submittingBeacon = CustomBeacon(name: name)
        let waitFor = expectation(description: "Wait For")
        var sentBeaconData: Data?
        reporter = Reporter(session, networkUtility: .wifi) {request, completion   in
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
            let expectedBeacon = try CoreBeaconFactory(session).map(submittingBeacon)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
            AssertEqualAndNotNil(serverBeacon.v, session.propertyHandler.properties.viewNameForCurrentAppState)
            AssertEqualAndNotNil(serverBeacon.cen, name)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }
}
