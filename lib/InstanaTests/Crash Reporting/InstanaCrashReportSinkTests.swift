//  Created by Nikola Lajic on 3/4/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaCrashReportSinkTests: XCTestCase {
    
    var sink: InstanaCrashReportSink!
    lazy var error = { InstanaError(code: .invalidRequest, description: "test error") }()
    var simulatedSubmissionFailure: InstanaEvents.Submitter { return { ($0 as? InstanaEventResultNotifiable)?.completion(.failure(error: self.error)) } }
    let simulatedSubmissionSuccess: InstanaEvents.Submitter = { ($0 as? InstanaEventResultNotifiable)?.completion(.success) }
    
    override func setUp() {
        KSCrash.sharedInstance().deleteBehaviorAfterSendAll = KSCDeleteAlways // reset default
        sink = InstanaCrashReportSink()
    }
    
    override func tearDown() {
        sink = nil
    }

    func test_callbackInvoked_withNoReports() {
        var callbackInvoked = false
        sink.filterReports([]) { reports, finished, error in
            XCTAssertTrue(finished)
            XCTAssertNil(error)
            callbackInvoked = true
        }
        XCTAssertTrue(callbackInvoked)
    }
    
    func test_ignoreCrashes_notConvertableToDictionary() {
        var callbackInvoked = false
        let r = ["not convertable to dict"]
        sink.filterReports(r) { reports, finished, error in
            XCTAssertEqual(r, reports as? [String])
            XCTAssertTrue(finished)
            XCTAssertNil(error)
            callbackInvoked = true
        }
        XCTAssertEqual(KSCrash.sharedInstance().deleteBehaviorAfterSendAll, KSCDeleteOnSucess)
        XCTAssertTrue(callbackInvoked)
    }
    
    func test_eventSubmissionError_shouldPropagateToCallback() {
        let exp = expectation(description: "Filtering done")
        sink.submitEvent = simulatedSubmissionFailure
        
        sink.filterReports([["a":"b"]]) { _, finished, callbackError in
            XCTAssertFalse(finished)
            XCTAssertEqual(self.error, callbackError as? InstanaError)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func test_revertToDefaultDeletionMethod_ifLocalReportIdNotAvailable() {
        let exp = expectation(description: "Filtering done")
        sink.submitEvent = simulatedSubmissionFailure
        
        XCTAssertEqual(KSCrash.sharedInstance().deleteBehaviorAfterSendAll, KSCDeleteAlways)
        sink.filterReports([["a":"b"]]) { _, _, _ in exp.fulfill() }
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(KSCrash.sharedInstance().deleteBehaviorAfterSendAll, KSCDeleteOnSucess)
    }
    
    func test_deleteLocalReports_ifLocalReportIdAvailable() {
        let exp = expectation(description: "Filtering done")
        sink.submitEvent = simulatedSubmissionSuccess
        var deletedIds: [NSNumber] = []
        sink.deleteReport = { deletedIds.append($0) }
        let reports = [
            ["standard": ["reportId": 1]],
            ["standard": ["reportId": 21]]
        ]
        
        sink.filterReports(reports) { _, finished, error in
            XCTAssertTrue(finished)
            XCTAssertNil(error)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(deletedIds, [1, 21])
    }
    
    func test_callbackInvoked_onSuccess() {
        let exp = expectation(description: "Filtering done")
        sink.submitEvent = simulatedSubmissionSuccess
        
        sink.filterReports([["a":"b"], ["a":"b"]]) { reports, finished, error in
            XCTAssertEqual(reports?.count, 2)
            XCTAssertTrue(finished)
            XCTAssertNil(error)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func test_completionNotInvoked_beforeSubmissionResult() {
        let exp = expectation(description: "Filtering done")
        var eventCount = 0
        sink.submitEvent = { event in
            // simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: {
                eventCount += 1
                (event as? InstanaEventResultNotifiable)?.completion(.success)
            })
        }
        
        sink.filterReports([["a":"b"], ["a":"b"]]) { _, _, _ in
            eventCount == 2 ? exp.fulfill() : XCTFail("Filtering callback should wait for submission result: \(eventCount)")
        }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func test_parsingData_fromCrashReport() {
        let exp = expectation(description: "Filtering done")
        var event: InstanaEvent?
        sink.submitEvent = { event = $0; ($0 as? InstanaEventResultNotifiable)?.completion(.success) }
        let report: [String: Any] = [
            "standard": [
                "report": [
                    "timestamp": "2019-03-04T14:08:58+00:00"
                ],
                "user": [
                    "breadcrumbs": ["a", "b", "c"],
                    "sessionId": "s"
                ]
            ],
            "json-encoded": "report-contents".data(using: .utf8) as Any
        ]
        
        sink.filterReports([report]) { _, _, _ in exp.fulfill() }
        
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertNotNil(event)
        guard let crashEvent = event as? InstanaCrashEvent else {
            XCTFail("Event type mismatch. Expected crash event, got: \(type(of: event))")
            return
        }
        XCTAssertEqual(crashEvent.timestamp, 1551708538)
        XCTAssertEqual(crashEvent.breadcrumbs, ["a", "b", "c"])
        XCTAssertEqual(crashEvent.sessionId, "s")
        XCTAssertEqual(crashEvent.report, "report-contents")
    }
}
