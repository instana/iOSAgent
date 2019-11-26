//  Created by Nikola Lajic on 3/19/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class RemoteCallMarkerTests: XCTestCase {

    func test_marker_defaultValues() {
        let start = Date().timeIntervalSince1970
        let marker = HTTPMarker(url: "a", method: "b", delegate: Delegate())
        XCTAssertEqual(marker.url, "a")
        XCTAssertEqual(marker.method, "b")
        XCTAssertEqual(marker.requestSize, 0)
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertEqual(marker.connectionType, nil)
        XCTAssertNotNil(UUID(uuidString: marker.eventId))
        XCTAssertTrue(marker.startTime >= start)
    }
    
    func test_marker_shouldNotRetainDelegate() {
        var delegate: Delegate = Delegate()
        weak var weakDelegate = delegate
        let marker = HTTPMarker(url: "c", method: "b", delegate: delegate)
        delegate = Delegate()
        XCTAssertNil(weakDelegate)
        XCTAssertEqual(marker.url, "c") // random test, so maker is not deallocated and no warning is shown
    }
    
    func test_marker_shouldAddTrackingHeaders_toNSMutableURLRequest() {
        let marker = HTTPMarker(url: "a", method: "b", delegate: Delegate())
        let request = NSMutableURLRequest(url: URL(string: "a")!)
        marker.addTrackingHeaders(to: request)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-INSTANA-T"), marker.eventId)
        XCTAssertNoThrow(marker.addTrackingHeaders(to: nil))
    }
    
    func test_marker_shouldAddTrackingHeaders_toURLRequest() {
        let marker = HTTPMarker(url: "a", method: "b", delegate: Delegate())
        var request = URLRequest(url: URL(string: "a")!)
        marker.addTrackingHeaders(to: &request)
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-INSTANA-T"), marker.eventId)
    }
    
    func test_unfinaliedMarkerDuration_shouldBeZero() {
        let marker = HTTPMarker(url: "a", method: "b", delegate: Delegate())
        XCTAssertEqual(marker.duration(), 0)
    }
    
    func test_finalizingMarker_withSuccess_shouldRetainOriginalValues() {
        let delegate = Delegate()
        let marker = HTTPMarker(url: "a", method: "b", requestSize: 4, delegate: delegate)
        
        marker.endedWith(responseCode: 200, responseSize: 123)
        marker.endedWith(responseCode: 300, responseSize: 321)
        marker.canceled()
        
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.requestSize, 4)
        XCTAssertEqual(marker.responseSize, 123)
        XCTAssertTrue(marker.duration() > 0)
        if case let .finished(responseCode) = marker.state {
            XCTAssertEqual(responseCode, 200)
        }
        else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finalizingMarker_withError_shouldRetainOriginalValues() {
        let delegate = Delegate()
        let marker = HTTPMarker(url: "a", method: "b", delegate: delegate)
        let error = CocoaError(CocoaError.coderValueNotFound)
        
        marker.endedWith(error: error, responseSize: 10)
        marker.endedWith(error: CocoaError(CocoaError.coderInvalidValue), responseSize: 20)
        marker.endedWith(responseCode: 300, responseSize: 321)
        
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.responseSize, 10)
        XCTAssertTrue(marker.duration() > 0)
        if case let .failed(e) = marker.state {
            XCTAssertEqual(e as? CocoaError, error)
        }
        else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finalizingMarker_withCancel_shouldRetainOriginalValues() {
        let delegate = Delegate()
        let marker = HTTPMarker(url: "a", method: "b", delegate: delegate)
        
        marker.canceled()
        marker.canceled()
        marker.endedWith(responseCode: 300, responseSize: 321)
        
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.responseSize, 0)
        XCTAssertTrue(marker.duration() > 0)
        if case .canceled = marker.state {} else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finishedMarker_toEventConversion() {
        let marker = HTTPMarker(url: "u", method: "m", requestSize: 111, connectionType: .wifi, delegate: Delegate())
        marker.endedWith(responseCode: 204, responseSize: 10)
        
        guard let event = marker.createEvent() as? HTTPEvent else {
            XCTFail("Event type missmatch"); return
        }
        XCTAssertEqual(event.eventId, marker.eventId)
        XCTAssertEqual(event.timestamp, marker.startTime)
        XCTAssertEqual(event.duration, marker.duration())
        XCTAssertEqual(event.method, "m")
        XCTAssertEqual(event.url, "u")
        XCTAssertEqual(event.responseCode, 204)
        XCTAssertEqual(event.requestSize, 111)
        XCTAssertEqual(event.responseSize, 10)
        XCTAssertEqual(event.connectionType, .wifi)
        XCTAssertEqual(event.result, "finished")
    }
    
    func test_failedMarker_toEventConversion() {
        let marker = HTTPMarker(url: "z", method: "t", requestSize: 123, connectionType: .cellular, delegate: Delegate())
        let error = CocoaError(CocoaError.coderValueNotFound)
        marker.endedWith(error: error)
        
        guard let event = marker.createEvent() as? HTTPEvent else {
            XCTFail("Event type missmatch"); return
        }
        XCTAssertEqual(event.eventId, marker.eventId)
        XCTAssertEqual(event.timestamp, marker.startTime)
        XCTAssertEqual(event.duration, marker.duration())
        XCTAssertEqual(event.method, "t")
        XCTAssertEqual(event.url, "z")
        XCTAssertEqual(event.responseCode, -1)
        XCTAssertEqual(event.requestSize, 123)
        XCTAssertEqual(event.responseSize, 0)
        XCTAssertEqual(event.connectionType, .cellular)
        XCTAssertEqual(event.result, String(describing: error as Error))
    }
    
    func test_canceledMarker_toEventConversion() {
        let marker = HTTPMarker(url: "f", method: "c", requestSize: 1, delegate: Delegate())
        marker.canceled()
        
        guard let event = marker.createEvent() as? HTTPEvent else {
            XCTFail("Event type missmatch"); return
        }
        XCTAssertEqual(event.eventId, marker.eventId)
        XCTAssertEqual(event.timestamp, marker.startTime)
        XCTAssertEqual(event.duration, marker.duration())
        XCTAssertEqual(event.method, "c")
        XCTAssertEqual(event.url, "f")
        XCTAssertEqual(event.responseCode, -1)
        XCTAssertEqual(event.requestSize, 1)
        XCTAssertEqual(event.responseSize, 0)
        XCTAssertEqual(event.result, "canceled")
    }
    
    func test_starteddMarker_toEventConversion() {
        let marker = HTTPMarker(url: "f", method: "c", requestSize: 1, delegate: Delegate())
        
        guard let event = marker.createEvent() as? HTTPEvent else {
            XCTFail("Event type missmatch"); return
        }
        XCTAssertEqual(event.eventId, marker.eventId)
        XCTAssertEqual(event.timestamp, marker.startTime)
        XCTAssertEqual(event.duration, 0)
        XCTAssertEqual(event.method, "c")
        XCTAssertEqual(event.url, "f")
        XCTAssertEqual(event.responseCode, -1)
        XCTAssertEqual(event.requestSize, 1)
        XCTAssertEqual(event.responseSize, 0)
        XCTAssertEqual(event.result, "started")
    }
}

extension RemoteCallMarkerTests {
    class Delegate: HTTPMarkerDelegate {
        var finaliedCount: Int = 0
        func finalized(marker: HTTPMarker) {
            finaliedCount += 1
        }
    }
}
