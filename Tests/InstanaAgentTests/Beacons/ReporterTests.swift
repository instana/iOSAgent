import XCTest
@testable import InstanaAgent
import Network

class ReporterTests: InstanaTestCase {

    var env: InstanaSession!
    var reporterRetainer: [Reporter]!

    override func setUp() {
        super.setUp()
        env = InstanaSession.mock
        // Need to retain the reporter otherwise the lifetime is not guranteed with all delays
        reporterRetainer = [Reporter]()
    }

    override func tearDown() {
        env = nil
        reporterRetainer = nil
        super.tearDown()
    }

    func test_submit() {
        // Given
        var didSchedule = false
        var didSubmit = false
        let submittedToQueue = expectation(description: "Submitted To Queue")
        let reporter = TestReporter(session(delay: 0.2)) {}
        reporter.didSchedule = {
            didSchedule = true
        }

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory)) {
            didSubmit = true
            submittedToQueue.fulfill()
        }
        wait(for: [submittedToQueue], timeout: 0.2)

        // Then
        AssertTrue(didSchedule)
        AssertTrue(didSubmit)
        AssertTrue(reporter.queue.items.count == 1)
    }

    func test_submit_multiple_must_be_delayed() {
        // Given
        var didSchedule = false
        var didSubmitFirst = false
        var didSubmitSecond = false
        let firstSubmittedToQueue = expectation(description: "Submitted To Queue")
        let secondSubmittedToQueue = expectation(description: "Submitted To Queue")
        let reporter = TestReporter(session(delay: 0.2)) {}
        reporter.didSchedule = {
            didSchedule = true
        }

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory)) {
            didSubmitFirst = true
            firstSubmittedToQueue.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory)) {
            didSubmitSecond = true
            secondSubmittedToQueue.fulfill()
        }
        wait(for: [firstSubmittedToQueue], timeout: 0.2)

        // Then
        AssertTrue(didSchedule)
        AssertTrue(didSubmitFirst)
        AssertTrue(didSubmitSecond == false)
        AssertTrue(reporter.queue.items.count == 1)

        // Wait more
        wait(for: [secondSubmittedToQueue], timeout: 0.2)
        AssertTrue(didSubmitSecond)
        AssertTrue(reporter.queue.items.count == 2)
    }

    func test_schedule_and_flush_once() {
        // Given
        var didFlush = false
        let expectflush = expectation(description: "Submitted To Queue")
        let reporter = TestReporter(session(delay: 0.0)) {
            didFlush = true
            expectflush.fulfill()
        }

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(for: [expectflush], timeout: 0.6)

        // Then
        AssertTrue(didFlush)
        AssertTrue(reporter.queue.items.count == 0)
    }

    func test_schedule_and_flush_once_with_multiple() {
        // Given
        var flushCount = 0
        let reporter = TestReporter(session(delay: 0.0)) {
            flushCount += 1
        }

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(0.5)

        // Then - Should only flush once when getting more beacons before flushing occured
        AssertTrue(flushCount == 1)
        AssertTrue(reporter.queue.items.count == 0)
    }

    func test_schedule_and_flush_twice() {
        // Given
        var flushCount = 0
        let reporter = TestReporter(session(delay: 0.0)) {
            flushCount += 1
        }

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        // Submit one more after delay
        wait(0.6)
        AssertTrue(flushCount == 1)
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(0.6)

        // Then - Should flush twice when getting more beacons after first flushing occured
        AssertTrue(flushCount == 2)
        AssertTrue(reporter.queue.items.count == 0)
    }

    //
    // Testing flushing the queue
    //

    /// Criteria:
    ///  - Suspend Sending: Never
    ///   - TransmissionDelay: 0.4
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent after delay of 0.4
    func test_submit_and_flush_with_delay() {
        // Given
        let submitExp = expectation(description: "Submit Expect")
        let finalExp = expectation(description: "Delayed sending")
        let delay = 0.4
        let givenBeacon = AlertBeacon(alertType: .lowMemory)

        let start = Date()
        var flushCount = 0
        var didSend: Date?
        let reporter = TestReporter(session(delay: delay)) {
            flushCount += 1
            didSend = Date()
            finalExp.fulfill()
        }

        // When
        reporter.submit(givenBeacon) {
            submitExp.fulfill()
        }
        wait(for: [submitExp], timeout: 0.4)

        // Then
        AssertTrue(reporter.queue.items.count == 1)
        AssertTrue(flushCount == 0)
        AssertEqualAndNotNil(reporter.queue.items.last?.bid, givenBeacon.id.uuidString)

        // Wait for final flush
        wait(for: [finalExp], timeout: delay * 2)

        // Then
        AssertTrue(flushCount == 1)
        AssertTrue(didSend?.timeIntervalSince(start) ?? 0.0 >= delay)
        AssertTrue(reporter.queue.items.count == 0)
    }


    /// Criteria:
    ///  - Suspend Sending: Never
    ///  - Low Battery TransmissionDelay: 0.4
    ///  - Battery: low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent after delay of 0.4
    func test_submit_delay_onLowBattery() {
        // Given
        let exp = expectation(description: "Delayed sending")
        let delay = 0.4
        let start = Date()
        var finished: Date?
        let reporter = Reporter(session(delay: delay), batterySafeForNetworking: { false }, networkUtility: .cell,
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
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0), batterySafeForNetworking: { true }, networkUtility: .none,
                                send: { _, _ in
                                    sendNotCalled = false
        })

        // When Offline
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.2, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.offline.rawValue)
    }

    /// Send when coming back offline again (starting offline
    /// Criteria:
    ///  - TransmissionDelay: 0.0
    ///  - Battery: Good
    ///  - Network: Offline and online delayed
    ///
    /// Expected Result - Report should NOT be sent (because we are offline)
    func test_submit_queue_when_back_online() {
        // Given
        let firstStep = expectation(description: "Dont_send_offline")
        let secondStep = expectation(description: "Send_when_back_online")
        var resultError: InstanaError?
        var sendCalled = false
        let networkUtility: NetworkUtility = .none
        let reporter = Reporter(session(delay: 0.0), batterySafeForNetworking: { true }, networkUtility: networkUtility,
                                send: { _, _ in
                                    sendCalled = true
                                    resultError = nil
                                    secondStep.fulfill()
        })

        // When Offline
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            resultError != nil ? firstStep.fulfill() : ()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(for: [firstStep], timeout: 5.0)

        // Then
        AssertTrue(sendCalled == false)
        AssertTrue(resultError?.code == InstanaError.Code.offline.rawValue)

        // When coming back online
        networkUtility.update(.wifi)
        wait(for: [secondStep], timeout: 10.0)

        // Then
        AssertTrue(sendCalled)
        AssertTrue(resultError == nil)
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
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.cellularConnection]),
                                batterySafeForNetworking: { true }, networkUtility: .cell,
                                send: { _, _ in
                                    sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.5, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_submiting_cellularConnection_lowBattery_wifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(session(delay: 0.0, suspend: [.cellularConnection]),
                                batterySafeForNetworking: { false }, networkUtility: .wifi,
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
    func test_submiting_cellularConnection_goodBattery_wifi() {
        // Given
        let exp = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(session(delay: 0.0, suspend: [.cellularConnection]),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
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
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.cellularConnection]),
                                batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.5, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.noWifiAvailable.rawValue)
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
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery]),
                                batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.lowBattery.rawValue)
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
        var didSendReport = false
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery]),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
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
        var didSendReport = false
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery]),
                                batterySafeForNetworking: { true }, networkUtility: .cell,
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
        var resultError: InstanaError?
        var didNOTSendReport = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery]),
                                batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didNOTSendReport = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(didNOTSendReport)
        AssertTrue(resultError?.code == InstanaError.Code.lowBattery.rawValue)
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
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery, .cellularConnection]),
                                batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        waitForExpectations(timeout: 0.3, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_goodBattery_noWIFI() {
        let waitForCompletion = expectation(description: "Delayed sending")
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery, .cellularConnection]),
                                batterySafeForNetworking: { true }, networkUtility: .cell,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            waitForCompletion.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(for: [waitForCompletion], timeout: 2)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.noWifiAvailable.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_lowBattery_WIFI() {
        var resultError: InstanaError?
        let waitForCompletion = expectation(description: "Delayed sending")
        var sendNotCalled = true
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery, .cellularConnection]),
                                batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        sendNotCalled = false
        })

        // When
        reporter.completion = {result in
            resultError = result.error as? InstanaError
            waitForCompletion.fulfill()
        }
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        wait(for: [waitForCompletion], timeout: 2)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError?.code == InstanaError.Code.lowBattery.rawValue)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_suspend_all_goodBattery_WIFI() {
        let waitForSend = expectation(description: "Delayed sending")
        var didSend = false
        let reporter = Reporter(session(delay: 0.0, suspend: [.lowBattery, .cellularConnection]),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSend = true
                                        waitForSend.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }


    // MARK: Test behaviour without suspending config

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_no_wifi_low_battery() {
        // Given
        var didSend = false
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { false }, networkUtility: .cell,
                                      send: { _, _ in
                                        didSend = true
                                        waitForSend.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_wifi_good_battery() {
        // Given
        var didSend = false
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSend = true
                                        waitForSend.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_wifi_low_battery() {
        // Given
        var didSend = false
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { false }, networkUtility: .wifi,
                                      send: { _, _ in
                                        didSend = true
                                        waitForSend.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_no_wifi_good_battery() {
        // Given
        var didSend = false
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .cell,
                                send: { _, _ in
                                    didSend = true
                                    waitForSend.fulfill()
        })

        // When
        reporter.submit(AlertBeacon(alertType: .lowMemory))

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }

    /// Criteria:
    ///
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - One more item should be allowed when queue is almost full (-1)
    func test_almost_full_queue_allows_one_new_beacon() {
        // Given
        let waitForSend = expectation(description: "Delayed sending")
        var didSend = false
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                send: { _, _ in
                                    didSend = true
                                    waitForSend.fulfill()
        })
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems - 1).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(env).map(beacons)
        reporter.queue.add(corebeacons)

        // When
        reporter.submit(HTTPBeacon.createMock())

        // Then
        wait(for: [waitForSend], timeout: 2)
        AssertTrue(didSend)
    }

    /// Criteria:
     ///
     ///  - Suspend Sending when: never
     ///  - Battery: Good
     ///  - WIFI: YES
     ///
     /// Expected Result - No more items should be allowed when queue is full. Items will be discarded
    func test_full_queue_discards_new_beacons() {
        // Given
        var shouldNotSend = true
        let reporter = Reporter(session(delay: 0.0),
                            batterySafeForNetworking: { true }, networkUtility: .wifi,
                            send: { _, _ in
                                shouldNotSend = false
        })
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(env).map(beacons)
        reporter.queue.add(corebeacons)

        // When
        reporter.submit(HTTPBeacon.createMock())
        wait(1.0)

        // Then
        AssertTrue(shouldNotSend)
        AssertEqualAndNotZero(reporter.queue.maxItems, 100)
    }

    // MARK: Test Result Code and Errors
    func test_send_Failure() {
        // Given
        let givenError = CocoaError(.coderInvalidValue)
        var resultError: CocoaError?
        let givenBeacon = HTTPBeacon.createMock()
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                send: { _, completion in
                                    completion(.failure(givenError))
        })

        // When
        reporter.completion = {result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let error = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            resultError = error
            waitForSend.fulfill()
        }
        reporter.submit(givenBeacon)
        wait(for: [waitForSend], timeout: 2.0)

        // Then
        AssertEqualAndNotNil(resultError, givenError)
        AssertEqualAndNotNil(reporter.queue.items.last?.bid, givenBeacon.id.uuidString)
    }

    func test_invalid_beacon_should_not_submitted() {
        // Given
        var shouldNotSend = true
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                      send: { _, _ in
                                        shouldNotSend = false
        })

        // When
        reporter.completion = {_ in
            shouldNotSend = false
        }
        reporter.submit(Beacon(timestamp: 1000000, sessionID: UUID()))

        // Then
        AssertTrue(shouldNotSend)
    }
    
    func test_submitSuccess_withStatusCodeIn200Range_shouldReportSuccess() {
        // Given
        let waitForSend = expectation(description: "waitForSend")
        var resultSuccess = 0
        let verifyResult: (BeaconResult) -> Void = {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
            resultSuccess += 1
            if resultSuccess == 3 {
                waitForSend.fulfill()
            }
        }

        // When
        mockBeaconSubmission(.success(statusCode: 200), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 204), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 299), resultCallback: verifyResult)
        wait(for: [waitForSend], timeout: 4.0)

        // Then
        AssertTrue(resultSuccess == 3)
    }
    
    func test_submitSuccess_withStatusCodeOutside200Range_shouldReportFailure() {
        // Given
        let waitForSend = expectation(description: "waitForSend")
        var resultError: InstanaError?
        var errorCount = 0
        let verifyResult: (BeaconResult) -> Void = {
            guard case let .failure(e) = $0 else { XCTFail("Invalid result: \($0)"); return }
            guard let error = e as? InstanaError else { XCTFail("Error type missmatch"); return }
            resultError = error
            errorCount += 1
            if errorCount == 4 {
                waitForSend.fulfill()
            }
        }

        // When
        mockBeaconSubmission(.success(statusCode: 100), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 300), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 400), resultCallback: verifyResult)
        mockBeaconSubmission(.success(statusCode: 500), resultCallback: verifyResult)
        wait(for: [waitForSend], timeout: 2.0)

        // Then
        AssertEqualAndNotZero(resultError?.code ?? 0, InstanaError.Code.invalidResponse.rawValue)
    }

    func test_submit_and_flush_shouldNotCause_RetainCycle() {
        // Given
        let waitForCompletion = expectation(description: "waitForSend")
        var reporter: Reporter? = Reporter(session(delay: 0.0)) { _, completion in
            completion(.success(statusCode: 200))
        }
        reporter?.completion = {result in
            waitForCompletion.fulfill()
        }
        weak var weakReporter = reporter

        // When
        reporter?.submit(HTTPBeacon.createMock())
        wait(for: [waitForCompletion], timeout: 2.0)
        reporter = nil

        // Then
        XCTAssertNil(weakReporter)
    }

    func test_queue_should_remove_sent_items_on_success() {
        let waitForSubmitNextBeacon = expectation(description: "Wait for Submit")
        var shouldCallCompletion = false
        let beacons: [HTTPBeacon] = (0...10).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(env).map(beacons)
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                send: { _, completion in
                                    completion(.success(statusCode: 200))
        })
        reporter.queue.add(corebeacons)
        reporter.completion = {_ in
            shouldCallCompletion = true
        }
        let nextBeacon = HTTPBeacon.createMock()

        // When
        reporter.submit(nextBeacon) {
            waitForSubmitNextBeacon.fulfill()
        }
        reporter.flushQueue()
        wait(for: [waitForSubmitNextBeacon], timeout: 3.0)

        // Then
        // The nextBeacon comes too late and is not part of the flushed beacons
        AssertTrue(shouldCallCompletion)
        AssertTrue(reporter.queue.items.count == 1)
        AssertEqualAndNotNil(reporter.queue.items.last?.bid, nextBeacon.id.uuidString)
    }

    func test_queue_should_be_cleared_after_flush_when_full_even_for_error() {
        var shouldCallCompletion = false
        let reporter = Reporter(session(delay: 0.0),
                                batterySafeForNetworking: { true }, networkUtility: .wifi,
                                send: { _, completion in
                                    completion(.failure(InstanaError(code: .invalidResponse, description: "SomeError")))
        })
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(env).map(beacons)
        reporter.queue.add(corebeacons)
        reporter.completion = {_ in
            shouldCallCompletion = true
        }

        // When
        reporter.flushQueue()

        // Then
        AssertTrue(shouldCallCompletion)
        AssertTrue(reporter.queue.items.isEmpty)
        AssertTrue(reporter.queue.isFull == false)
    }
}


// MARK: Test CreateBatchRequest
extension ReporterTests {

    func test_createBatchRequest() {
        // Given
        env = session(delay: 0.0)
        let reporter = Reporter(env) { _, _ in}
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let cbeacons = try! CoreBeaconFactory(env).map(beacons)
        let data = cbeacons.asString.data(using: .utf8)
        let gzippedData = try? data?.gzipped(level: .bestCompression)

        // When
        let sut = try? reporter.createBatchRequest(from: cbeacons.asString)

        // Then
        AssertEqualAndNotNil(sut?.httpMethod, "POST")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Type"], "text/plain")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Encoding"], "gzip")
        AssertEqualAndNotNil(sut?.allHTTPHeaderFields?["Content-Length"], "\(gzippedData?.count ?? 0)")
        AssertEqualAndNotNil(sut?.url, env.configuration.reportingURL)
        AssertEqualAndNotNil(sut?.httpBody, gzippedData)
    }

    func test_createBatchRequest_invalid_key() {
        // Given
        let invalidConfig = InstanaConfiguration.mock(key: "")
        env = InstanaSession.mock(configuration: invalidConfig)
        let reporter = Reporter(env) { _, _ in}
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let corebeacons = try! CoreBeaconFactory(env).map(beacons)

        // When
        XCTAssertThrowsError(try reporter.createBatchRequest(from: corebeacons.asString)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.notAuthenticated.rawValue)
        }
    }
}

extension ReporterTests {

    func session(delay: Instana.Types.Seconds, suspend: Set<InstanaConfiguration.SuspendReporting> = []) -> InstanaSession {
        var config = InstanaConfiguration.mock
        config.transmissionDelay = delay
        config.transmissionLowBatteryDelay = delay
        config.suspendReporting = suspend
        return InstanaSession.mock(configuration: config)
    }

    class TestReporter: Reporter {
        var didFlushQueue: () -> Void
        var didSchedule: (() -> Void)?
        init(_ env: InstanaSession, _ didFlushQueue: @escaping () -> Void) {
            self.didFlushQueue = didFlushQueue
            super.init(env)
            self.queue.items.removeAll()
        }
        override func flushQueue() {
            queue.items.removeAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.didFlushQueue()
            }
            super.flushQueue()
        }

        override func scheduleFlush() {
            didSchedule?()
            super.scheduleFlush()
        }
    }

    func mockBeaconSubmission(_ loadResult: InstanaNetworking.Result, resultCallback: @escaping (BeaconResult) -> Void) {
        var config = InstanaConfiguration.mock
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        let reporter = Reporter(.mock(configuration: config),
                            batterySafeForNetworking: { true },
                            networkUtility: .wifi,
                            send: { _, callback in callback(loadResult) })
        reporter.queue.removeAll()
        reporter.completion = resultCallback
        reporter.submit(AlertBeacon(alertType: .lowMemory))
        reporterRetainer.append(reporter)
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
