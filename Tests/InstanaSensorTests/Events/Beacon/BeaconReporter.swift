//  Created by Nikola Lajic on 3/7/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class ReporterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Instana.setup(withKey: "KEY") // needed for mocking submission
    }

    override func tearDown() {
        Instana.setup(withKey: "")
        super.tearDown()
    }

    func test_internalTimer_shouldNotCauseRetainCycle() {
        var reporter: BeaconReporter? = BeaconReporter(transmissionDelay: 0.01) { _, _, _ in}
        weak var weakReporter = reporter
        let exp = expectation(description: "Delay")
        
        reporter?.submit(Event(timestamp: 0))
        reporter = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertNil(weakReporter)
    }
    
    func test_changingBuffer_sendsQueuedEvents() {
        let exp = expectation(description: "test_changingBuffer_sendsQueuedEvents")
        var requestMade = false
        let reporter = BeaconReporter(transmissionDelay: 10) { _, _, _ in
            requestMade = true
            exp.fulfill()
        }
        
        reporter.submit(CustomEvent(name: "Custom"))
        reporter.bufferSize = 10

        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertTrue(requestMade)
    }
    
    func test_delayEventSubmission_onLowBattery() {
        let exp = expectation(description: "Delayed sending")
        var count = 0
        let reporter = BeaconReporter(transmissionDelay: 0.05,
                                      transmissionLowBatteryDelay: 0.01,
                                      batterySafeForNetworking: { count += 1; return count >= 3 },
                                      load: { _, _, _ in
                                        XCTAssertEqual(count, 3)
                                        exp.fulfill()
        })
        reporter.suspendReporting = .lowBattery
        
        reporter.submit(AlertEvent(alertType: .lowMemory, screen: nil))
        
        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func test_loadError_shouldBeParsedToError() {
        let error = CocoaError(.coderInvalidValue)
        mockEventSubmission(.failure(error: error)) { result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let resultError = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            XCTAssertEqual(resultError, error)
        }
    }
    
    func test_loadSuccess_withStatusCodeIn200Range_shouldReportSuccess() {
        mockEventSubmission(.success(statusCode: 200)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockEventSubmission(.success(statusCode: 204)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockEventSubmission(.success(statusCode: 299)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
    }
    
    func test_loadSuccess_withStatusCodeOutside200Range_shouldReportFailure() {
        let verifyResult: (EventResult) -> Void = {
            guard case let .failure(e) = $0 else { XCTFail("Invalid result: \($0)"); return }
            guard let resultError = e as? InstanaError else { XCTFail("Error type missmatch"); return }
            XCTAssertEqual(resultError.code, InstanaError.Code.invalidResponse.rawValue)
        }
        
        mockEventSubmission(.success(statusCode: 100), resultCallback: verifyResult)
        mockEventSubmission(.success(statusCode: 300), resultCallback: verifyResult)
        mockEventSubmission(.success(statusCode: 400), resultCallback: verifyResult)
        mockEventSubmission(.success(statusCode: 500), resultCallback: verifyResult)
    }
}

extension ReporterTests {
    func mockEventSubmission(_ loadResult: InstanaNetworking.Result, resultCallback: @escaping (EventResult) -> Void) {
        let reporter = BeaconReporter(transmissionDelay: 0.05,
                                      load: { _, _, callback in callback(loadResult) })
        
        reporter.submit(Event(sessionId: "SessionID", eventId: "EventID", timestamp: 1000000))
    }
}
