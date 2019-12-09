//  Created by Nikola Lajic on 3/7/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor
import Network

class ReporterTests: XCTestCase {

    var config: InstanaConfiguration!

    override func setUp() {
        super.setUp()
        config = InstanaConfiguration.default(key: "KEY")
    }


    /// Criteria:
    ///  - Suspend Sending: Never
    ///   - TransmissionDelay: 0.4
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent after delay of 0.4
    func test_send_delay() {
        // Given
        let exp = expectation(description: "Delayed sending")

        let delay = 0.4
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = delay
        config.transmissionLowBatteryDelay = 0.0

        let start = Date()
        var didSend: Date?
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        didSend = Date()
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: delay * 2, handler: nil)
        

        // Then
        AssertTrue(didSend != nil)
        AssertTrue(didSend?.timeIntervalSince(start) ?? 0.0 >= delay)
    }

    /// Criteria:
    ///  - Suspend Sending: Never
    ///  - Low Battery TransmissionDelay: 0.4
    ///  - Battery: low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent after delay of 0.4
    func test_send_delay_onLowBattery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        let delay = 0.4
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = delay
        config.transmissionLowBatteryDelay = delay

        let start = Date()
        var finished: Date?

        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        finished = Date()
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: delay * 2, handler: nil)


        // Then
        AssertTrue(finished != nil)
        AssertTrue(finished?.timeIntervalSince(start) ?? 0.0 >= delay)
    }

    /// Don't send when offline
    /// Criteria:
    ///  - TransmissionDelay: 0.0
    ///  - Battery: Good
    ///  - Network: Offline
    ///
    /// Expected Result - Report should NOT be sent (because we are offline)
    func test_dont_send_when_offline() {
        // Given
        let exp = expectation(description: "Dont_send_offline")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var expectedError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .none,
                                send: { _, _ in
                                    sendNotCalled = false
        })

        // When Offline
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.2, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.offline.rawValue)
    }

    /// Send when coming back offline again (starting offline
    /// Criteria:
    ///  - TransmissionDelay: 0.0
    ///  - Battery: Good
    ///  - Network: Offline and online delayed
    ///
    /// Expected Result - Report should NOT be sent (because we are offline)
    func test_send_queue_when_back_online() {
        // Given
        let firstStep = expectation(description: "Dont_send_offline")
        let secondStep = expectation(description: "Send_when_back_online")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var expectedError: InstanaError?
        var sendCalled = false
        let networkUtility: NetworkUtility = .none
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: networkUtility,
                                send: { _, _ in
                                    sendCalled = true
                                    expectedError = nil
                                    secondStep.fulfill()
        })

        // When Offline
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            expectedError != nil ? firstStep.fulfill() : ()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(for: [firstStep], timeout: 5.0)

        // Then
        AssertTrue(sendCalled == false)
        AssertTrue(expectedError?.code == InstanaError.Code.offline.rawValue)

        // When coming back online
        networkUtility.update(.wifi)
        wait(for: [secondStep], timeout: 10.0)

        // Then
        AssertTrue(sendCalled)
        AssertTrue(expectedError == nil)
    }

    // MARK: Test suspending behavior on NO WIFI connection

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should NOT be sent
    func test_suspend_cellularConnection_goodBattery_noWifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_sending_cellularConnection_lowBattery_wifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_sending_cellularConnection_goodBattery_wifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should NOT be sent
    func test_suspsend_cellularConnection_lowBattery_noWIFI() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    // MARK: Test suspending behavior on LOW Battery
    /// Criteria:
    ///  - Suspend Sending when: Battery low
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspendLowBattery_lowBattery_noWifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.lowBattery]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.lowBattery.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_suspendLowBattery_goodBattery_Wifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.lowBattery]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent
    func test_suspendLowBattery_goodBattery_noWifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.lowBattery]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should NOT be sent
    func test_suspendLowBattery_lowBattery_WIFI() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.lowBattery]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didNOTSendReport = true
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didNOTSendReport = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didNOTSendReport)
        AssertTrue(expectedError?.code == InstanaError.Code.lowBattery.rawValue)
    }

    // MARK: Test suspending behavior on all (NO WIFI and low Battery)

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_lowBattery_noWIFI() {
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.lowBattery, .cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_goodBattery_noWIFI() {
        let exp = expectation(description: "Delayed sending")
        var expectedError: InstanaError?
        var config = self.config!
        config.suspendReporting = [.lowBattery, .cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
                                        exp.fulfill()
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_lowBattery_WIFI() {
        var expectedError: InstanaError?
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.lowBattery, .cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var sendNotCalled = true
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            expectedError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(expectedError?.code == InstanaError.Code.lowBattery.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_suspend_all_goodBattery_WIFI() {
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = [.lowBattery, .cellularConnection]
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }


    // MARK: Test behaviour without suspending confi

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should be sent
    func test_sending_no_wifi_low_battery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_sending_wifi_good_battery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_sending_wifi_low_battery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should be sent
    func test_sending_no_wifi_good_battery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        var didSendReport = false
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        didSendReport = true
                                        exp.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didSendReport)
    }

    // MARK: Test Result Code and Errors
    func test_loadError() {
        // Given
        let givenError = CocoaError(.coderInvalidValue)
        var expectedError: CocoaError?
        let exp = expectation(description: "Delayed sending")

        // When
        mockBeaconSubmission(.failure(givenError)) { result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let resultError = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            expectedError = resultError
            exp.fulfill()
        }

        waitForExpectations(timeout: 0.6, handler: nil)

        // Then
        AssertEqualAndNotNil(expectedError, givenError)
    }

    func test_invalid_beacon_should_not_send() {
        // Given
        var shouldNotSend = true
        var config = self.config!
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        let reporter = Reporter(config, batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        shouldNotSend = false
        })

        // When
        reporter.completion = {_ in
            shouldNotSend = false
        }
        reporter.submit(Beacon(timestamp: 1000000, sessionId: "ID"))

        // Then
        AssertTrue(shouldNotSend)
    }
    
    func test_loadSuccess_withStatusCodeIn200Range_shouldReportSuccess() {
        mockBeaconSubmission(.success(statusCode: 200)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockBeaconSubmission(.success(statusCode: 204)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockBeaconSubmission(.success(statusCode: 299)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
    }
    
    func test_loadSuccess_withStatusCodeOutside200Range_shouldReportFailure() {
        let verifyResult: (BeaconResult) -> Void = {
            guard case let .failure(e) = $0 else { XCTFail("Invalid result: \($0)"); return }
            guard let resultError = e as? InstanaError else { XCTFail("Error type missmatch"); return }
            XCTAssertEqual(resultError.code, InstanaError.Code.invalidResponse.rawValue)
        }
        
        mockBeaconSubmission(.success(statusCode: 100), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 300), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 400), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 500), resultCallback: verifyResult)
    }

    // MARK: Test Timer
    func test_internalTimer_shouldNotCauseRetainCycle() {
        // Given
        var config = self.config!
        config.suspendReporting = []
        config.transmissionDelay = 0.01
        config.transmissionLowBatteryDelay = 0.0
        var reporter: Reporter? = Reporter(config) { _, _ in}
        weak var weakReporter = reporter
        let exp = expectation(description: "Delay")

        // When
        reporter?.submit(Beacon(timestamp: 0))
        reporter = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.2, handler: nil)

        // Then
        XCTAssertNil(weakReporter)
    }
}

// MARK: Test CreateBatchRequest
extension ReporterTests {

    func test_createBatchRequest() {
        // Given
        var config = self.config!
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        let reporter = Reporter(config) { _, _ in}
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let cbeacons = try! CoreBeaconFactory(config).map(beacons)
        let data = cbeacons.asString.data(using: .utf8)
        let gzippedData = try? data?.gzipped(level: .bestCompression)

        // When
        let sut = try? reporter.createBatchRequest(from: cbeacons)

        // Then
        AssertEqualAndNotNil(sut?.httpMethod, "POST")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Type"], "text/plain")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Encoding"], "gzip")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Length"], "\(gzippedData?.count ?? 0)")
        AssertEqualAndNotNil(sut?.url, config.reportingURL)
        AssertEqualAndNotNil(sut?.httpBody, gzippedData)
    }

    func test_createBatchRequest_invalid_key() {
        // Given
        var config = self.config!
        config.key = ""
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        let reporter = Reporter(config) { _, _ in}
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let corebeacons = try! CoreBeaconFactory(config).map(beacons)

        // When
        XCTAssertThrowsError(try reporter.createBatchRequest(from: corebeacons)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.notAuthenticated.rawValue)
        }
    }
}

extension ReporterTests {
    func mockBeaconSubmission(_ loadResult: InstanaNetworking.Result, resultCallback: @escaping (BeaconResult) -> Void) {
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        let reporter = Reporter(config,
                                      batterySafeForNetworking: { true },
                                      networkUtility: .wifi,
                                      send: { _, callback in callback(loadResult) })
        reporter.completion = resultCallback
        reporter.submit(AlertBeacon(alertType: .lowMemory))
    }
}

extension NetworkUtility {
    static var wifi: NetworkUtility { utility(connectionType: .wifi) }
    static var cell: NetworkUtility { utility(connectionType: .cellular) }
    static var none: NetworkUtility { utility(connectionType: .none) }

    static func utility(connectionType: NetworkUtility.ConnectionType) -> NetworkUtility {
        let util = NetworkUtility(connectionType: connectionType)
        if #available(iOS 12.0, *) {
            // We disable the monitor updater to have more control in our tests
            util.pathMonitor.cancel()
        }
        return util
    }
}
