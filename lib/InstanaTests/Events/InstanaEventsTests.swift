//  Created by Nikola Lajic on 3/7/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaEventsTests: XCTestCase {
    
    func test_overwrittenEventCallbackInvoked() {
        let events = InstanaEvents { _, _, _ in}
        events.bufferSize = 1
        var result: InstanaEventResult?
        let exp = expectation(description: "Event callback")
        
        let event = InstanaCrashEvent(sessionId: "", timestamp: 0, report: "", breadcrumbs: nil) {
            result = $0
            exp.fulfill()
        }
        events.submit(event: event)
        events.submit(event: InstanaEvent(timestamp: 0))
        
        waitForExpectations(timeout: 0.1)
        XCTAssertNotNil(result)
        guard case let .failure(e)? = result else { XCTFail("Result is not error"); return }
        guard let error = e as? InstanaError else { XCTFail("Error type missmatch"); return }
        XCTAssertEqual(error.code, InstanaError.Code.bufferOverwrite.rawValue)
    }
    
    func test_internalTimer_shouldNotCauseRetainCycle() {
        var events: InstanaEvents? = InstanaEvents(transmissionDelay: 0.01) { _, _, _ in}
        weak var weakEvents = events
        let exp = expectation(description: "Delay")
        
        events?.submit(event: InstanaEvent(timestamp: 0))
        events = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.2, handler: nil)
        XCTAssertNil(weakEvents)
    }
    
    func test_changingBuffer_sendsQueuedEvents() {
        var requestMade = false
        let events: InstanaEvents = InstanaEvents(transmissionDelay: 10) { _, _, _ in
            requestMade = true
        }
        
        events.submit(event: InstanaEvent(timestamp: 0))
        events.bufferSize = 10
        
        XCTAssertTrue(requestMade)
    }
    
    func test_delayEventSubmission_onLowBattery() {
        let exp = expectation(description: "Delayed sending")
        var count = 0
        let events = InstanaEvents(transmissionDelay: 0.05,
                                   transmissionLowBatteryDelay: 0.01,
                                   eventsToRequest: { _ in URLRequest(url: URL(string: "www.a.a")!) },
                                   batterySafeForNetworking: { count += 1; return count >= 3 },
                                   load: { _, _, _ in
                                    XCTAssertEqual(count, 3)
                                    exp.fulfill()
        })
        events.suspendReporting = .lowBattery
        
        events.submit(event: InstanaAlertEvent(alertType: .lowMemory, screen: nil))
        
        waitForExpectations(timeout: 0.2, handler: nil)
    }
    
    func test_loadError_shouldBeParsedToError() {
        let error = CocoaError(.coderInvalidValue)
        mockEventSubmission(with: .failure(error: error)) { result in
            guard case let .failure(e) = result else { XCTFail("Invalid result"); return }
            guard let resultError = e as? CocoaError else { XCTFail("Error type missmatch"); return }
            XCTAssertEqual(resultError, error)
        }
    }
    
    func test_loadSuccess_withStatusCodeIn200Range_shouldReportSuccess() {
        mockEventSubmission(with: .success(statusCode: 200)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockEventSubmission(with: .success(statusCode: 204)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
        mockEventSubmission(with: .success(statusCode: 299)) {
            guard case .success = $0 else { XCTFail("Result missmatch"); return }
        }
    }
    
    func test_loadSuccess_withStatusCodeOutside200Range_shouldReportFailure() {
        let verifyResult: (InstanaEventResult) -> Void = {
            guard case let .failure(e) = $0 else { XCTFail("Invalid result: \($0)"); return }
            guard let resultError = e as? InstanaError else { XCTFail("Error type missmatch"); return }
            XCTAssertEqual(resultError.code, InstanaError.Code.invalidResponse.rawValue)
        }
        
        mockEventSubmission(with: .success(statusCode: 100), resultCallback: verifyResult)
        mockEventSubmission(with: .success(statusCode: 300), resultCallback: verifyResult)
        mockEventSubmission(with: .success(statusCode: 400), resultCallback: verifyResult)
        mockEventSubmission(with: .success(statusCode: 500), resultCallback: verifyResult)
    }
}

extension InstanaEventsTests {
    func mockEventSubmission(with loadResult: InstanaNetworking.Result, resultCallback: @escaping (InstanaEventResult) -> Void) {
        let exp = expectation(description: "Delayed sending")
        let events = InstanaEvents(transmissionDelay: 0.05,
                                   eventsToRequest: { _ in URLRequest(url: URL(string: "www.a.a")!) },
                                   load: { _, _, callback in callback(loadResult) })
        
        events.submit(event: InstanaCrashEvent(sessionId: "1", timestamp: 0, report: "", breadcrumbs: nil, completion: { result in
            resultCallback(result)
            exp.fulfill()
        }))
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}
