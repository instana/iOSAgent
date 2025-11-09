import XCTest
@testable import InstanaAgent
import Network

class ReporterTests: InstanaTestCase {

    var reporterRetainer: [Reporter]!

    override func setUp() {
        super.setUp()
        session = InstanaSession.mock
        // Need to retain the reporter otherwise the lifetime is not guranteed with all delays
        reporterRetainer = [Reporter]()
    }

    override func tearDown() {
        session = nil
        reporterRetainer = nil
        super.tearDown()
    }

    func test_submit() {
        // Given
        var didSubmit = false
        let submittedToQueue = expectation(description: "Submitted To Queue")
        let reporter = createReporterDefaultWifi()

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            didSubmit = true
            submittedToQueue.fulfill()
        }
        wait(for: [submittedToQueue], timeout: 3.0)

        // Then
        AssertTrue(didSubmit)
    }

    func test_collection_not_enabled() {
        // Given
        session = InstanaSession.mock(configuration: config)
        session.collectionEnabled = false

        var didSubmit = false
        let submittedToQueue = expectation(description: "Submitted To Queue")
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi)

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {result in
            didSubmit = result
            submittedToQueue.fulfill()
        }
        wait(for: [submittedToQueue], timeout: 3.0)

        // Then
        AssertFalse(didSubmit)
    }

    func test_submit_rateLimit_two_NOT_exceeded() {
        // Given
        let submittedToQueue1 = expectation(description: "Submitted First Beacon")
        let submittedToQueue2 = expectation(description: "Submitted Second Beacon")
        let rateLimiter = ReporterRateLimiter(configs: [.init(timeout: 30.0, maxItems: 2)])
        let reporter = createReporterDefaultWifi(delay: 10.0, rateLimiter: rateLimiter)

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            submittedToQueue1.fulfill()
        }
        wait(for: [submittedToQueue1], timeout: 3.0)

        // Submit another beacon that should be rejected
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            submittedToQueue2.fulfill()
        }
        wait(for: [submittedToQueue2], timeout: 3.0)

        // Then - the second beacon is also in the queue - no beacon has been dropped
        AssertTrue(reporter.queue.items.count == 2)
    }

    func test_submit_rateLimit_exceeds() {
        // Given
        let submittedToQueue1 = expectation(description: "Submitted First Beacon")
        let submittedToQueue2 = expectation(description: "Submitted Second Beacon")
        let rateLimiter = ReporterRateLimiter(configs: [.init(timeout: 30.0, maxItems: 1)])
        let reporter = createReporterDefaultWifi(delay: 10.0, rateLimiter: rateLimiter)

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            submittedToQueue1.fulfill()
        }
        wait(for: [submittedToQueue1], timeout: 3.0)

        // Submit another beacon that should be rejected
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            submittedToQueue2.fulfill()
        }
        wait(for: [submittedToQueue2], timeout: 3.0)

        // Then : only one beacon should be the in queue - the second has been dropped
        AssertTrue(reporter.queue.items.count == 1)
    }

    func test_submit_multiple_must_be_delayed() {
        // Given
        var didSubmitFirst = false
        var didSubmitSecond = false
        let firstSubmittedToQueue = expectation(description: "Submitted To Queue")
        let secondSubmittedToQueue = expectation(description: "Submitted To Queue")
        let reporter = createReporterDefaultWifi()
        reporterRetainer.append(reporter)

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            didSubmitFirst = true
            firstSubmittedToQueue.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory)) {_ in
            didSubmitSecond = true
            secondSubmittedToQueue.fulfill()
        }
        wait(for: [firstSubmittedToQueue], timeout: 2.0)

        // Then
        AssertTrue(didSubmitFirst)
        AssertTrue(didSubmitSecond == false)
        AssertTrue(reporter.queue.items.count == 1)

        // When Wait more
        wait(for: [secondSubmittedToQueue], timeout: 3.0)

        // Then
        AssertTrue(didSubmitSecond)
        AssertTrue(reporter.queue.items.count == 2)
    }

    func test_schedule_and_flush_once() {
        // Given
        let expectflush = expectation(description: "Submitted To Queue")
        let reporter = createReporterDefaultWifi([expectflush])

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [expectflush], timeout: 3)

        // Then
        AssertTrue(reporter.queue.items.count == 0)
    }

    func test_schedule_and_flush_once_with_multiple() {
        // Given
        let expectflush = expectation(description: "Wait for")
        var sendCount = 0
        let reporter = createReporterDefaultWifi([expectflush]) { sendCount = $0 }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [expectflush], timeout: 2.0)

        // Then - Should only flush once when getting more beacons before flushing occured
        AssertEqualAndNotZero(sendCount, 1)
        AssertEqualAndNotNil(reporter.queue.items.count, 5)
    }

    func test_schedule_and_flush_twice() {
        // Given
        let waitForFirst = expectation(description: "Wait For 1st")
        let waitForSecond = expectation(description: "Wait For 2nd")
        var sendCount = 0
        let reporter = createReporterDefaultWifi([waitForFirst, waitForSecond]) { sendCount = $0 }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForFirst], timeout: 2.0)
        AssertEqualAndNotZero(sendCount, 1)
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSecond], timeout: 4.0)

        // Then - Should flush twice when getting more beacons after first flushing occured
        AssertEqualAndNotZero(sendCount, 2)
        AssertTrue(reporter.queue.items.isEmpty)
    }

    //
    // Testing flushing the queue
    //

    /// Criteria:
    ///  - Suspend Sending: Never
    ///   - reporterSendDebounce: 0.4
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report should be sent after delay of 0.3
    func test_submit_and_flush_with_delay() {
        // Given
        let submitExp = expectation(description: "Submit Expect")
        let finalExp = expectation(description: "Delayed sending")
        let delay = 0.5
        let givenBeacon = PerformanceBeacon(subType: .lowMemory)
        var sendCount = 0
        let start = Date()
        var didSend: Date?
        let reporter = createReporterDefaultWifi(delay: delay, [finalExp]) {
            didSend = Date()
            sendCount = $0
        }

        // When
        reporter.submit(givenBeacon) {_ in
            submitExp.fulfill()
        }
        wait(for: [submitExp], timeout: 3.0)

        // Then
        AssertTrue(reporter.queue.items.count == 1)
        AssertTrue(sendCount == 0)
        AssertEqualAndNotNil(reporter.queue.items.randomElement()?.bid, givenBeacon.id)

        // Wait for final flush
        wait(for: [finalExp], timeout: 5.0)

        // Then
        AssertEqualAndNotZero(sendCount, 1, "Send count must be 1 and not \(sendCount)")
        AssertTrue(didSend?.timeIntervalSince(start) ?? 0.0 >= delay)
        AssertTrue(reporter.queue.items.count == 0)
    }


    /// Criteria:
    ///  - Suspend Sending: Never
    ///  - Low Battery reporterSendDebounce: 0.4
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
        let reporter = Reporter(createMockSession(delay), batterySafeForNetworking: { false }, networkUtility: .cell) { _, _ in
            finished = Date()
            exp.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        waitForExpectations(timeout: delay * 5, handler: nil)

        // Then
        AssertTrue(finished != nil)
        AssertTrue(finished?.timeIntervalSince(start) ?? 0.0 >= delay)
    }

    /// Don't send when offline
    /// Criteria:
    ///  - reporterSendDebounce: 0.0
    ///  - Battery: Good
    ///  - Network: Offline
    ///
    /// Expected Result - Report should NOT be sent (because we are offline)
    func test_dont_send_when_offline() {
        // Given
        let waitFor = expectation(description: "Dont_send_offline")
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { true }, networkUtility: .none) { _, _ in
            sendNotCalled = false
        }

        // When Offline
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitFor.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 5.0)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.offline)
    }

    /// Send when coming back offline again (starting offline
    /// Criteria:
    ///  - reporterSendDebounce: 0.0
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
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { true }, networkUtility: networkUtility) { _, _ in
            sendCalled = true
            resultError = nil
            secondStep.fulfill()
        }

        // When Offline
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            resultError != nil ? firstStep.fulfill() : ()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [firstStep], timeout: 5.0)

        // Then
        AssertTrue(sendCalled == false)
        AssertTrue(resultError == InstanaError.offline)

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
        let reporter = Reporter(createMockSession(suspend: [.cellularConnection]), batterySafeForNetworking: { true }, networkUtility: .cell) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        waitForExpectations(timeout: 2.0, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.noWifiAvailable)
    }

    /// Criteria:
    ///  - Suspend Sending when: Connected to cellular
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_submiting_cellularConnection_lowBattery_wifi() {
        // Given
        let waitFor = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(createMockSession(suspend: [.cellularConnection]), batterySafeForNetworking: { false }, networkUtility: .wifi) { _, _ in
            didSendReport = true
            waitFor.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

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
        let waitFor = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(createMockSession(suspend: [.cellularConnection]), batterySafeForNetworking: { true }, networkUtility: .wifi) { _, _ in
            didSendReport = true
            waitFor.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

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
        let reporter = Reporter(createMockSession(suspend: [.cellularConnection]), batterySafeForNetworking: { false }, networkUtility: .cell) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            exp.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        waitForExpectations(timeout: 2.0, handler: nil)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.noWifiAvailable)
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
        let waitFor = expectation(description: "Delayed sending")
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(createMockSession(suspend: [.lowBattery]), batterySafeForNetworking: { false }, networkUtility: .cell) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitFor.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.lowBattery)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report should be sent
    func test_suspendLowBattery_goodBattery_Wifi() {
        // Given
        let waitFor = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(createMockSession(suspend: [.lowBattery]), batterySafeForNetworking: { true }, networkUtility: .wifi) { _, _ in
            didSendReport = true
            waitFor.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

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
        let waitFor = expectation(description: "Delayed sending")
        var didSendReport = false
        let reporter = Reporter(createMockSession(suspend: [.lowBattery]), batterySafeForNetworking: { true }, networkUtility: .cell) { _, _ in
            didSendReport = true
            waitFor.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

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
        let waitFor = expectation(description: "Delayed sending")
        var resultError: InstanaError?
        var didNOTSendReport = true
        let reporter = Reporter(createMockSession(suspend: [.lowBattery]), batterySafeForNetworking: { false }, networkUtility: .wifi) { _, _ in
            didNOTSendReport = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitFor.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

        // Then
        AssertTrue(didNOTSendReport)
        AssertTrue(resultError == InstanaError.lowBattery)
    }

    // MARK: Test suspending behavior on all (NO WIFI and low Battery)

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Low
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should NOT be sent
    func test_suspend_all_lowBattery_noWIFI() {
        let waitFor = expectation(description: "Delayed sending")
        var resultError: InstanaError?
        var sendNotCalled = true
        let reporter = Reporter(createMockSession(suspend: [.lowBattery, .cellularConnection]), batterySafeForNetworking: { false }, networkUtility: .cell) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitFor.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitFor], timeout: 2.0)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.noWifiAvailable)
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
        let reporter = Reporter(createMockSession(suspend: [.lowBattery, .cellularConnection]), batterySafeForNetworking: { true }, networkUtility: .cell) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitForCompletion.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForCompletion], timeout: 4)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.noWifiAvailable)
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
        let reporter = Reporter(createMockSession(suspend: [.lowBattery, .cellularConnection]), batterySafeForNetworking: { false }, networkUtility: .wifi) { _, _ in
            sendNotCalled = false
        }

        // When
        reporter.completionHandler.append {result in
            resultError = result.error as? InstanaError
            waitForCompletion.fulfill()
        }
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForCompletion], timeout: 2)

        // Then
        AssertTrue(sendNotCalled)
        AssertTrue(resultError == InstanaError.lowBattery)
    }

    /// Criteria:
    ///  - Suspend Sending when: Battery low AND NO WIFI
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_suspend_all_goodBattery_WIFI() {
        let waitForSend = expectation(description: "Delayed sending")
        var sendCount = 0
        let reporter = Reporter(createMockSession(suspend: [.lowBattery, .cellularConnection]), batterySafeForNetworking: { true }, networkUtility: .wifi) { _, _ in
            sendCount += 1
            waitForSend.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSend], timeout: 2)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
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
        var sendCount = 0
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { false }, networkUtility: .cell) { _, _ in
            sendCount += 1
            waitForSend.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSend], timeout: 2)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_wifi_good_battery() {
        // Given
        var sendCount = 0
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = createReporterDefaultWifi([waitForSend]) {
            sendCount = $0
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSend], timeout: 2)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Low
    ///  - WIFI: YES
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_wifi_low_battery() {
        // Given
        var sendCount = 0
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { false }, networkUtility: .wifi) { _, _ in
            sendCount += 1
            waitForSend.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSend], timeout: 2)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
    }

    /// Criteria:
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: NO
    ///
    /// Expected Result - Report with beacons should be sent
    func test_submiting_no_wifi_good_battery() {
        // Given
        var sendCount = 0
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { true }, networkUtility: .cell)  { _, _ in
            sendCount += 1
            waitForSend.fulfill()
        }

        // When
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        wait(for: [waitForSend], timeout: 2)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
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
        var sendCount = 0
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = createReporterDefaultWifi([waitForSend]) {
            sendCount = $0
        }
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems - 1).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(session).map(beacons)
        reporter.queue.add(corebeacons)

        // When
        reporter.submit(HTTPBeacon.createMock())
        wait(for: [waitForSend], timeout: 10)

        // Then
        AssertEqualAndNotZero(sendCount, 1)
    }

    /// Criteria:
    ///
    ///  - Suspend Sending when: never
    ///  - Battery: Good
    ///  - WIFI: YES
    ///
    /// Expected Result - No more items should be allowed when queue is full. Items will be discarded (100 items limit reached)
    func test_full_queue_discards_new_beacons() {
        // Given
        let waitFor = expectation(description: "test_full_queue_discards_new_beacons")
        let reporter = createReporterDefaultWifi()
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(session).map(beacons)
        reporter.queue.add(corebeacons)

        // Before
        AssertEqualAndNotZero(reporter.queue.maxItems, InstanaConfiguration.mock.maxQueueSize)
        AssertEqualAndNotZero(reporter.queue.maxItems, reporter.queue.items.count)
        AssertTrue(reporter.queue.maxItems > 0)

        // When
        reporter.submit(HTTPBeacon.createMock()) {_ in
            waitFor.fulfill()
        }
        wait(for: [waitFor], timeout: 2.0)

        // Then
        AssertEqualAndNotZero(reporter.queue.maxItems, reporter.queue.items.count)
    }

    func test_flush_queue_when_going_into_background() {
        // Given
        let waitForSend = expectation(description: "Wait for send")
        let reporter = createReporterDefaultWifi([waitForSend])

        // When
        reporter.submit(HTTPBeacon.createMock())
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        wait(for: [waitForSend], timeout: 2.0)

        // Then
        AssertTrue(reporter.queue.items.isEmpty)
    }

    // MARK: Test Prequeu
    func test_preque_items() {
        // Given
        let beacon = HTTPBeacon.createMock()
        var expectedResult: BeaconResult?
        let prequeueTime = 2.0
        let viewName = "ViewName"
        let waitForSubmit = expectation(description: "Wait for Submit")
        let waitForSend = expectation(description: "Wait for send")
        let sendQueue = MockInstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 2)
        let mockSession = createMockSession(0.0, preQueueUsageTime: prequeueTime)
        mockSession.propertyHandler.properties.view = nil
        let reporter = Reporter(mockSession, batterySafeForNetworking: { true }, networkUtility: .wifi, queue: sendQueue) { _, completion in
            completion(.success(200))
        }

        // When
        reporter.submit(beacon) {_ in
            waitForSubmit.fulfill()
        }
        reporter.completionHandler.append {result in
            expectedResult = result
            waitForSend.fulfill()
        }

        // Then
        wait(for: [waitForSubmit], timeout: 2.0)
        AssertTrue(beacon.viewName == nil)
        AssertTrue(mockSession.propertyHandler.properties.view == nil)
        AssertTrue(mockSession.propertyHandler.properties.user == nil)
        AssertTrue(mockSession.propertyHandler.properties.getMetaData().isEmpty)
        AssertTrue(reporter.preQueue.count == 1)

        // When
        mockSession.propertyHandler.properties.view = ViewChange(viewName: viewName)
        mockSession.propertyHandler.properties.appendMetaData("key", "someVal")
        mockSession.propertyHandler.properties.user = InstanaProperties.User(id: "123", email: "e@e.com", name: "John")
        wait(for: [waitForSend], timeout: prequeueTime * 2)

        // Then
        AssertTrue(reporter.preQueue.isEmpty)
        AssertTrue(expectedResult == .success)
        AssertTrue(sendQueue.addedItems.count == 1)
        AssertEqualAndNotNil(sendQueue.addedItems.first?.bid, beacon.id)
        AssertEqualAndNotNil(sendQueue.addedItems.first?.v, viewName)
        AssertEqualAndNotNil(sendQueue.addedItems.first?.ue, "e@e.com")
        AssertEqualAndNotNil(sendQueue.addedItems.first?.un, "John")
        AssertEqualAndNotNil(sendQueue.addedItems.first?.ui, "123")
        AssertEqualAndNotNil(sendQueue.addedItems.first?.m, ["key": "someVal"])
    }

    func test_submit_after_preque_time() {
        // Given
        let beaconPreQueue = HTTPBeacon.createMock()
        let beaconAfterQueue = HTTPBeacon.createMock()
        let prequeueTime = 0.5
        var sendCount = 0
        let waitForSubmit1 = expectation(description: "Wait for submit1")
        let waitForSend = expectation(description: "Wait for send")
        let sendQueue = MockInstanaPersistableQueue<CoreBeacon>(identifier: "queue", maxItems: 2)
        let mockSession = createMockSession(0.0, preQueueUsageTime: prequeueTime)
        let reporter = Reporter(mockSession, batterySafeForNetworking: { true }, networkUtility: .wifi, queue: sendQueue) { _, completion in
            completion(.success(200))
            sendCount += 1
            if sendCount == 2 {
                waitForSend.fulfill()
            }
        }

        // When
        reporter.submit(beaconPreQueue) {_ in
            waitForSubmit1.fulfill()
        }

        // Then
        wait(for: [waitForSubmit1], timeout: 5.0)
        AssertTrue(reporter.preQueue.first === beaconPreQueue)
        AssertTrue(reporter.preQueue.count == 1)

        // When
        wait(prequeueTime + 0.5)
        reporter.submit(beaconAfterQueue)
        wait(for: [waitForSend], timeout: prequeueTime + 0.5)

        // Then
        AssertEqualAndNotNil(sendCount, 2) // The prequeue has been flushed only
        AssertTrue(sendQueue.addedItems.count == 2)
        AssertTrue(sendQueue.addedItems.map {$0.bid}.contains(beaconPreQueue.id))
        AssertTrue(sendQueue.addedItems.map {$0.bid}.contains(beaconAfterQueue.id))
        AssertTrue(reporter.preQueue.isEmpty)
    }


    // MARK: Test Result Code and Errors
    func test_send_Failure() {
        // Given
        let givenError = CocoaError(.coderInvalidValue)
        var resultError: CocoaError?
        let givenBeacon = HTTPBeacon.createMock()
        weak var waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { true }, networkUtility: .wifi) { _, completion in
            completion(.failure(givenError))
        }

        // When
        reporter.completionHandler.append {result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let error = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            resultError = error
            waitForSend?.fulfill()
            waitForSend = nil
        }
        reporter.submit(givenBeacon)
        wait(for: [waitForSend!], timeout: 2.0)

        // Then
        AssertEqualAndNotNil(resultError, givenError)
        AssertEqualAndNotNil(reporter.queue.items.randomElement()?.bid, givenBeacon.id)
    }

    func test_send_Failure_noRetryDeleteBeacon() {
        // Given
        let givenError = CocoaError(.coderInvalidValue)
        var resultError: CocoaError?
        let givenBeacon = HTTPBeacon.createMock()
        weak var waitForSend = expectation(description: "Beacon deleted on send failure")

        let mockSession = createMockSession()
        mockSession.configuration.maxBeaconResendTries = 0
        let reporter = Reporter(mockSession, batterySafeForNetworking: { true }, networkUtility: .wifi) { _, completion in
            completion(.failure(givenError))
        }

        // When
        reporter.completionHandler.append {result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let error = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            resultError = error
            waitForSend?.fulfill()
        }
        reporter.submit(givenBeacon)
        wait(for: [waitForSend!], timeout: 2.0)

        // Then
        AssertEqualAndNotNil(resultError, givenError)
        AssertTrue(reporter.queue.items.count == 0)
    }

    func test_DO_NOT_remove_from_after_http_client_error() {
        // Given
        let beacon = HTTPBeacon.createMock()
        let mockQueue = MockInstanaPersistableQueue<CoreBeacon>(identifier: "", maxItems: 2)
        let givenError = InstanaError.httpClientError(400)
        let waitForSend = expectation(description: "Delayed sending")
        let reporter = Reporter(.mock, batterySafeForNetworking: { true }, networkUtility: .wifi, queue: mockQueue) { _, completion in
            completion(.failure(givenError))
        }

        // When
        reporter.completionHandler.append {result in
            waitForSend.fulfill()
        }
        reporter.submit(beacon)
        wait(for: [waitForSend], timeout: 20.0)

        // Then
        AssertTrue(reporter.queue.items.contains(where: {$0.bid == beacon.id}))
        AssertTrue(mockQueue.removedItems.isEmpty)
    }

    func test_invalid_beacon_should_not_submitted() {
        // Given
        let waitForSubmit = expectation(description: "wait for submit")
        let reporter = createReporterDefaultWifi()

        // When
        reporter.submit(Beacon(timestamp: 1000000)) {_ in
            waitForSubmit.fulfill()
        }

        // Then
        wait(for: [waitForSubmit], timeout: 2.0)
        AssertTrue(reporter.queue.items.isEmpty)
    }
    
    func test_submitSuccess_withStatusCodeIn200Range_shouldReportSuccess1() {
        common_StatusCodeIn200Range(200)
    }

    func test_submitSuccess_withStatusCodeIn200Range_shouldReportSuccess2() {
        common_StatusCodeIn200Range(204)
    }

    func test_submitSuccess_withStatusCodeIn200Range_shouldReportSuccess3() {
        common_StatusCodeIn200Range(299)
    }

    func common_StatusCodeIn200Range(_ errCode: Int) {
        // Given
        let waitForSend = expectation(description: "waitForSend")
        var resultSuccess = 0
        let verifyResult: (BeaconResult) -> Void = {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
            resultSuccess += 1
            if resultSuccess == 1 {
                waitForSend.fulfill()
            }
        }

        // When
        mockBeaconSubmission(.success(errCode), resultCallback: verifyResult)
        wait(for: [waitForSend], timeout: 5.0)

        // Then
        AssertTrue(resultSuccess == 1)
    }

    func test_withStatusCodeOutside200Range_shouldReportFailure1() {
        common_StatusCodeOutside200Range(.failure(InstanaError.httpClientError(400)),
                                         400, InstanaError.httpClientError(400))
    }
    func test_withStatusCodeOutside200Range_shouldReportFailure2() {
        common_StatusCodeOutside200Range(.failure(InstanaError.httpClientError(499)),
                                         499, InstanaError.httpClientError(499))
    }
    func test_withStatusCodeOutside200Range_shouldReportFailure3() {
        common_StatusCodeOutside200Range(.failure(InstanaError.httpServerError(500)),
                                         500, InstanaError.httpServerError(500))
    }
    func test_withStatusCodeOutside200Range_shouldReportFailure4() {
        common_StatusCodeOutside200Range(.failure(InstanaError.httpServerError(599)),
                                         599, InstanaError.httpServerError(599))
    }

    func common_StatusCodeOutside200Range(_ loadResult: Swift.Result<Int, Error>,
                                          _ errCode: Int, _ instErr: InstanaError) {
        // Given
        weak var waitForSend = expectation(description: "waitForSend")
        var resultErrors = [InstanaError]()
        let verifyResult: (BeaconResult) -> Void = {
            guard case let .failure(e) = $0 else { XCTFail("Invalid result: \($0)"); return }
            guard let error = e as? InstanaError else { XCTFail("Error type missmatch"); return }
            resultErrors.append(error)
            waitForSend?.fulfill()
            waitForSend = nil
        }

        // When
        mockBeaconSubmission(loadResult, resultCallback: verifyResult)
        wait(for: [waitForSend!], timeout: 3.0)

        // Then
        AssertTrue(resultErrors.contains(instErr))
    }

    func test_canScheduleFlush_not_allowed_while_flushing() {
        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi)
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)

        // When
        reporter.scheduleFlush()

        // Then
        XCTAssertFalse(reporter.canScheduleFlush())
    }

    func test_canScheduleFlush_lastFlushStartTime_nil() {
        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi)
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)

        // When
        reporter.scheduleFlush()

        reporter.lastFlushStartTime = nil // Force scheduling 2nd flushing

        // Then
        XCTAssertTrue(reporter.canScheduleFlush())
    }


    func test_canScheduleFlush_maxFlushingTimeExceeded() {
        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi)
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)

        // When
        reporter.scheduleFlush()

        // last flush time is stale, force flushing
        reporter.lastFlushStartTime = reporter.lastFlushStartTime! - (10.0+1) * 60
        // Then
        XCTAssertTrue(reporter.canScheduleFlush())
    }

    func test_calcDebounceTime_moreThanHalf() {
        // Given
        session.configuration.reporterSendDebounce = 2.0
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi)

        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems/2 + 1).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(session).map(beacons)
        reporter.queue.add(corebeacons)

        // When
        let debounce = reporter.calcDebounceTime()

        // Then
        XCTAssertTrue(debounce == 1.0)
    }

    func test_submit_and_flush_shouldNotCause_RetainCycle() {
        // Given
        let waitForCompletion = expectation(description: "waitForSend")
        var reporter: Reporter? = Reporter(createMockSession(), send:  { _, completion in
            completion(.success(200))
        })
        reporter?.completionHandler.append {result in
            waitForCompletion.fulfill()
        }
        weak var weakReporter = reporter

        // When
        reporter?.submit(HTTPBeacon.createMock())
        wait(for: [waitForCompletion], timeout: 2.0)
        reporter = nil

        // Then
        wait(0.2)
        XCTAssertNil(weakReporter)
    }

    func test_flushQueue_success() {
        var sentCount = 0
        var sentResult: BeaconResult?
        let waitFor = expectation(description: "test_flushQueue_success")
        let reporter = Reporter(.mock, send:  { _, completion in
            sentCount += 1
            completion(.success(200))
        })
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock(), HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {result in
            sentResult = result
            waitFor.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 4.0)

        // Then
        XCTAssertNil(sentResult?.error)
        XCTAssertEqual(sentCount, 1)
        XCTAssertTrue(reporter.queue.items.isEmpty)
    }

    func test_flushQueue_failure() {
        var sentCount = 0
        let httpError = [InstanaError.httpServerError(500), InstanaError.httpClientError(404)].randomElement()!
        var sentResult: BeaconResult?
        let waitFor = expectation(description: "test_flushQueue_failure")
        let reporter = Reporter(.mock, send:  { _, completion in
            sentCount += 1
            completion(.failure(httpError))
        })
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {result in
            sentResult = result
            waitFor.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 4.0)

        // Then
        XCTAssertEqual(sentResult?.error as! InstanaError, httpError)
        XCTAssertEqual(sentCount, 1)
        XCTAssertFalse(reporter.queue.items.isEmpty)
    }

    func hjtest_flushQueue_failure_gotoSlowSendMode() {
        let slowSendInterval = 1.0
        let httpError = [InstanaError.invalidRequest, InstanaError.missingAppKey].randomElement()!
        let waitFor = expectation(description: "test_flushQueue_failure")
        let reporter = Reporter(.mock(configuration: .mock(slowSendInterval: slowSendInterval)),
                                send:  { _, completion in
            completion(.failure(httpError))
        })
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {result in
            waitFor.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 1.0)

        // Then
        XCTAssertTrue(reporter.isInSlowSendMode)
        XCTAssertFalse(reporter.queue.items.isEmpty)
    }

    func hjtest_flushQueue_success_turnsOffSlowSendMode() {
        let slowSendInterval = 1.0
        let reporter = Reporter(.mock(configuration: .mock(slowSendInterval: slowSendInterval)),
                                send:  { _, completion in
            completion(.success(200))
        })

        reporter.setSlowSendStartTime(Date())
        XCTAssertTrue(reporter.isInSlowSendMode)

        // case 2, the reporter is now in slow send mode
        // a successful beacon send turns slow send mode off
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        let waitFor2 = expectation(description: "test_flushQueue_success_turnsOffSlowSendMode")
        reporter.completionHandler.removeAll()
        reporter.completionHandler.append {result in
            waitFor2.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor2], timeout: (slowSendInterval + 1.0))  // wait time should be greater than slowSendInterval
        // Then
        XCTAssertFalse(reporter.isInSlowSendMode)
    }

    func hjtest_flushQueue_debounceInterval() {
        let slowSendInterval = 3.0
        let httpError = [InstanaError.httpServerError(504), InstanaError.invalidResponse].randomElement()!
        let waitFor = expectation(description: "test_flushQueue_failure")
        let reporter = Reporter(.mock(configuration: .mock(slowSendInterval: slowSendInterval)),
                                send:  { _, completion in
            completion(.failure(httpError))
        })
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {result in
            waitFor.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 1.0)

        // Then
        XCTAssertTrue(reporter.isInSlowSendMode)
        XCTAssertFalse(reporter.queue.items.isEmpty)
    }

    func test_flushQueue_debounceSetTo_slowSendInterval() {
        let slowSendInterval = 3.0
        var beaconFlushed = false
        let reporter = Reporter(.mock(configuration: .mock(slowSendInterval: slowSendInterval)),
                                send:  { _, completion in
            beaconFlushed = true
            completion(.success(200))
        })

        // case 2, the reporter is now in slow send mode with debounce interval set to slowSendInterval
        reporter.sendFirstBeacon = false
        reporter.setSlowSendStartTime(Date())
        XCTAssertTrue(reporter.isInSlowSendMode)

        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        let waitFor2 = expectation(description: "test_flushQueue_debounceSetTo_slowSendInterval")
        reporter.completionHandler.append {result in
            waitFor2.fulfill()
        }

        // When
        reporter.scheduleFlush()
        Thread.sleep(forTimeInterval: (slowSendInterval / 2.0)) // wait time is less than than slowSendInterval
        // Then
        XCTAssertFalse(beaconFlushed)

        // case 3, wait long enough now
        wait(for: [waitFor2], timeout: (slowSendInterval + 2.0))
        // Then
        XCTAssertTrue(beaconFlushed)
    }

    func hjtest_retry_flushQueue_after_failure() {
        var sentCount = 0
        let retries = 1
        let expectecSentCount = 2
        let httpError = InstanaError.httpServerError(500)
        var sentResult: BeaconResult?
        let waitFor = expectation(description: "test_retry_flushQueue_after_failure")
        let reporter = Reporter(.mock(configuration: .mock(maxRetries: retries)), send:  { _, completion in
            sentCount += 1
            if sentCount == 1 {
                // First connection has error
                completion(.failure(httpError))
            } else {
                // second connection: First retry
                completion(.success(200))
            }
        })
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {result in
            sentResult = result
            if sentCount == expectecSentCount {
                waitFor.fulfill()
            } else if sentCount == 1 {
                XCTAssertEqual(sentResult?.error as! InstanaError, httpError)
                XCTAssertEqual(reporter.queue.items.count, 1)
            }
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 10.0)

        // Then
        XCTAssertNotNil(sentResult?.error)
        XCTAssertEqual(sentCount, expectecSentCount)
        XCTAssertTrue(reporter.queue.items.isEmpty)
    }

    func test_queue_should_NOT_be_cleared_after_flush_when_full_even_for_error() {
        var shouldCallCompletion = false
        let waitFor = expectation(description: "test_queue_should_NOT_be_cleared_after_flush_when_full_even_for_error")
        let reporter = Reporter(createMockSession(), batterySafeForNetworking: { true }, networkUtility: .wifi) { _, completion in
            completion(.failure(InstanaError.invalidResponse))
        }
        let beacons: [HTTPBeacon] = (0..<reporter.queue.maxItems).map { _ in HTTPBeacon.createMock() }
        let corebeacons = try! CoreBeaconFactory(.mock).map(beacons)
        reporter.queue.add(corebeacons)
        reporter.completionHandler.append {_ in
            shouldCallCompletion = true
            waitFor.fulfill()
        }

        // When
        reporter.scheduleFlush()
        wait(for: [waitFor], timeout: 4.0)

        // Then
        AssertTrue(shouldCallCompletion)
        corebeacons.forEach {
            AssertTrue(reporter.queue.items.contains($0))
        }
        AssertTrue(reporter.queue.isFull)
    }

    func test_runBackgroundFlush() {
        let waitForSend = expectation(description: "Wait for send")

        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi){ _, _ in
            waitForSend.fulfill()
        }

        XCTAssertNil(reporter.flusher)

        // When
        let corebeacons = try! CoreBeaconFactory(session).map([HTTPBeacon.createMock()])
        reporter.queue.add(corebeacons)

        reporter.runBackgroundFlush()
        wait(for: [waitForSend], timeout: 1)

        // Then
        XCTAssertNotNil(reporter.flusher)
    }
}


// MARK: Test CreateBatchRequest
extension ReporterTests {

    func test_createBatchRequest() {
        // Given
        let config: InstanaConfiguration = .mock(gzipReport: true)
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let cbeacons = try! CoreBeaconFactory(session).map(beacons)
        let flusher = BeaconFlusher(reporter: nil, items: [], debounce: 0, config: config, queue: .main, send: nil) { _ in}
        let data = cbeacons.asString.data(using: .utf8)
        let gzippedData = try? data?.gzipped(level: .bestCompression)

        // When
        let sut = try? flusher.createBatchRequest(from: cbeacons.asString)

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
        let invalidConfig = InstanaConfiguration.mock(key: "")
        let flusher = BeaconFlusher(reporter: nil, items: [], debounce: 0, config: invalidConfig, queue: .main, send: nil) { _ in}
        let beacons = [HTTPBeacon.createMock(), HTTPBeacon.createMock()]
        let corebeacons = try! CoreBeaconFactory(session).map(beacons)

        // When
        XCTAssertThrowsError(try flusher.createBatchRequest(from: corebeacons.asString)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError), InstanaError.missingAppKey)
        }
    }

    func test_deleteOldBeacons_true() {
        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi) { _, _ in
        }
        reporter.queue.items = createCoreBeaconSet()
        AssertEqualAndNotNil(reporter.queue.items.count, 5)

        // When
        reporter.purgeOldBeacons(true)

        // Then
        AssertEqualAndNotNil(reporter.queue.items.count, 3)
    }

    func test_deleteOldBeacons_false() {
        // Given
        let reporter = Reporter(session, batterySafeForNetworking: { true }, networkUtility: .wifi) { _, _ in
        }
        reporter.queue.items = createCoreBeaconSet()
        let originalCount = reporter.queue.items.count
        AssertEqualAndNotNil(reporter.queue.items.count, originalCount)

        // When
        reporter.purgeOldBeacons(false)

        // Then
        AssertEqualAndNotNil(reporter.queue.items.count, originalCount)
    }
}

extension ReporterTests {

    func createMockSession(_ delay: Instana.Types.Seconds = 0.0, preQueueUsageTime: Instana.Types.Seconds = 0.0, suspend: Set<InstanaConfiguration.SuspendReporting> = [], gzip: Bool = false) -> InstanaSession {
        let config = InstanaConfiguration.mock(gzipReport: gzip)
        config.reporterSendDebounce = delay
        config.reporterSendLowBatteryDebounce = delay
        config.preQueueUsageTime = preQueueUsageTime
        config.suspendReporting = suspend
        // A big max try number keeps beacons in the queue on failure case
        config.maxBeaconResendTries = 999
        return InstanaSession.mock(configuration: config)
    }

    func createReporterDefaultWifi(delay: TimeInterval = 0.0,
                                   preQueueUsageTime: TimeInterval = 0.0,
                                   rateLimiter: ReporterRateLimiter? = nil,
                                   queue: InstanaPersistableQueue<CoreBeacon>? = nil,
                                   _ expectations: [XCTestExpectation] = [],
                                   _ sent: ((Int) -> Void)? = nil) -> Reporter {
        var sendCount = 0
        let reporter = Reporter(createMockSession(delay, preQueueUsageTime: preQueueUsageTime),
                        batterySafeForNetworking: { true },
                        networkUtility: .wifi,
                        rateLimiter: rateLimiter,
                        queue: queue,
                        send: { _, callback in
                            callback(.success(200))
                        })
        reporter.completionHandler.append { result in
            sendCount += 1
            sent?(sendCount)
            if sendCount <= expectations.count {
                expectations[sendCount - 1].fulfill()
            }
        }
        return reporter
    }

    func mockBeaconSubmission(_ loadResult: Swift.Result<Int, Error>, resultCallback: @escaping (BeaconResult) -> Void) {
        let config = InstanaConfiguration.mock
        config.reporterSendDebounce = 0.0
        config.reporterSendLowBatteryDebounce = 0.0
        let reporter = Reporter(.mock(configuration: config),
                                batterySafeForNetworking: { true },
                                networkUtility: .wifi) { _, callback in
            callback(loadResult)
        }
        reporter.queue.removeAll()
        reporter.completionHandler.append(resultCallback)
        reporter.submit(PerformanceBeacon(subType: .lowMemory))
        reporterRetainer.append(reporter)
    }
    
    func createCoreBeaconSet() -> Set<CoreBeacon> {
        let beacons = [HTTPBeacon.createMock(timestamp: Date().millisecondsSince1970 - (30 * 60 * 1000)), //30 minutes old beacon
                       HTTPBeacon.createMock(timestamp: Date().millisecondsSince1970 - (16 * 60 * 1000)), //16 minutes old beacon
                       HTTPBeacon.createMock(timestamp: Date().millisecondsSince1970 + (16 * 60 * 1000)), //16 minutes new beacon not possible
                       HTTPBeacon.createMock(timestamp: Date().millisecondsSince1970 + (3 * 60 * 1000)), //3 minutes new beacon not feasible
                       HTTPBeacon.createMock()]
        do {
            return try Set(CoreBeaconFactory(InstanaSession.mock).map(beacons))
        } catch {
            XCTFail("Could not create CoreBeacon set")
        }
        return []
    }
}

extension NetworkUtility {
    static var wifi: NetworkUtility { utility(connectionType: .wifi) }
    static var cell: NetworkUtility { utility(connectionType: .cellular) }
    static var none: NetworkUtility { utility(connectionType: .none) }

    static func utility(connectionType: NetworkUtility.ConnectionType) -> NetworkUtility {
        let util = NetworkUtility(observeNetworkChanges: false)
        util.connectionType = connectionType
        return util
    }
}

extension BeaconResult: Equatable {
    public static func == (lhs: BeaconResult, rhs: BeaconResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success): return true
        case let (.failure(lerror), .failure(rerror)): return lerror as NSError? == rerror as NSError?
        default: return false
        }
    }
}
