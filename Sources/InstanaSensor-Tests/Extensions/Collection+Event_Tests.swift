//  Created by Nikola Lajic on 3/5/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class CollectionEvent_Tests: XCTestCase {
    
    func test_invokingCallbackOnEventCollection_shouldInvokeIndividualEventCallbacks() {
        var eventCount = 0
        let e1 = TestNotifiableEvent{ _ in eventCount += 1 }
        let e2 = TestNotifiableEvent { _ in eventCount += 1 }
        let e3 = Event(timestamp: Date().timeIntervalSinceReferenceDate)
        
        [e1, e2, e3].invokeCallbackIfNeeded(.success)
        
        XCTAssertEqual(eventCount, 2)
    }

    func test_batchRequestDefaultParameters() {
        Instana.setup(withKey: "a", reportingUrl: "http://b.com/")
        let request = try? [Event(timestamp: Date().timeIntervalSinceReferenceDate)].toBatchRequest()
        
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.url?.absoluteString, "http://b.com/v1/api/a/batch")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.allHTTPHeaderFields?["Content-Type"], "application/json")
    }
    
    func test_batchRequest_shouldThrow_forInvalidRequestURL() {
        let requests = [Event(timestamp: Date().timeIntervalSinceReferenceDate)]
        XCTAssertThrowsError(try requests.toBatchRequest(key: "a", reportingUrl: "")) {
            XCTAssertEqual(($0 as? InstanaError)?.code, InstanaError.Code.invalidRequest.rawValue)
        }
    }
    
    func test_batchRequest_shouldThrow_forMissingKey() {
        let requests = [Event(timestamp: Date().timeIntervalSinceReferenceDate)]
        XCTAssertThrowsError(try requests.toBatchRequest(key: nil)) {
            XCTAssertEqual(($0 as? InstanaError)?.code, InstanaError.Code.notAuthenticated.rawValue)
        }
    }
    
    func test_batchRequest_shouldThrow_forInvalidJSONContent() {
        let requests = [TestCustomJSONEvent(json: ["a": NSObject()])]
        XCTAssertThrowsError(try requests.toBatchRequest(key: "a")) {
            XCTAssertEqual(($0 as? InstanaError)?.code, InstanaError.Code.invalidRequest.rawValue)
        }
    }
    
    func test_batchRequest_contentIsCompressed() {
        let request = try? [TestCustomJSONEvent(json: ["a": "a"])].toBatchRequest(key: "a")
        
        XCTAssertEqual(request?.allHTTPHeaderFields?["Content-Encoding"], "gzip")
        XCTAssertEqual(request?.allHTTPHeaderFields?["Content-Length"], "11")
        XCTAssertEqual(request?.httpBody?.count, 11)
    }
    
    func test_batchRequest_incompresableContent_shouldNotBeCompressed() {
        let request = try? [TestCustomJSONEvent(json: [:])].toBatchRequest(key: "a") {_ in throw CocoaError(.coderInvalidValue) }
        
        XCTAssertNil(request?.allHTTPHeaderFields?["Content-Encoding"])
        XCTAssertNil(request?.allHTTPHeaderFields?["Content-Length"])
        XCTAssertEqual(request?.httpBody?.count, 4)
    }
    
    func test_batchRequest_contentIsSerializedToJSON() {
        let content = ["a": "a", "b": "b"]
        let request = try? [TestCustomJSONEvent(json: content)].toBatchRequest(key: "a") {_ in throw CocoaError(.coderInvalidValue) } // skip compression
        
        guard let data = request?.httpBody else {
            XCTFail("No content")
            return
        }
        guard let decodedContent = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]]) as [[String : String]]??) else {
            XCTFail("Failed to deserialize content")
            return
        }
        XCTAssertEqual(content, decodedContent?.first)
    }
}

extension CollectionEvent_Tests {
    private class TestNotifiableEvent: Event, EventResultNotifiable {
        let completion: EventResultNotifiable.CompletionBlock
        
        init(completion: @escaping EventResultNotifiable.CompletionBlock) {
            self.completion = completion
            super.init(timestamp: Date().timeIntervalSinceReferenceDate)
        }
    }
    
    private class TestCustomJSONEvent: Event {
        var json: [String: Any]
        
        init(json: [String: Any]) {
            self.json = json
            super.init(timestamp: Date().timeIntervalSinceReferenceDate)
        }
        
        override func toJSON() -> [String : Any] {
            return json
        }
    }
}
