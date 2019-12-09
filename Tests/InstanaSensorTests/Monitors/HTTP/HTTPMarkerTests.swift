//  Created by Nikola Lajic on 3/19/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class HTTPMarkerTests: XCTestCase {

    func test_marker_defaultValues() {
        // Given
        let url: URL = .random
        let start = Date().millisecondsSince1970
        let marker = HTTPMarker(url: url, method: "GET", delegate: Delegate())

        // Then
        XCTAssertEqual(marker.url, url)
        XCTAssertEqual(marker.method, "GET")
        XCTAssertEqual(marker.requestSize, 0)
        XCTAssertEqual(marker.trigger, .automatic)
        XCTAssertTrue(marker.startTime >= start)
    }
    
    func test_marker_shouldNotRetainDelegate() {
        // Given
        let url: URL = .random
        var delegate: Delegate = Delegate()
        weak var weakDelegate = delegate
        let sut = HTTPMarker(url: url, method: "b", delegate: delegate)
        delegate = Delegate()

        // Then
        XCTAssertNil(weakDelegate)
        XCTAssertEqual(sut.url, url) // random test, so maker is not deallocated and no warning is shown
    }

    func test_unfinaliedMarkerDuration_shouldBeZero() {
        // Given
        let sut = HTTPMarker(url: .random, method: "b", delegate: Delegate())

        // Then
        XCTAssertEqual(sut.duration, 0)
    }
    
    func test_finalizingMarker_withSuccess_shouldRetainOriginalValues() {
        // Given
        let delegate = Delegate()
        let marker = HTTPMarker(url: .random, method: "b", requestSize: 4, delegate: delegate)

        // When
        wait(0.1)
        marker.ended(responseCode: 200, responseSize: 123)
        marker.ended(responseCode: 300, responseSize: 321)
        marker.canceled()

        // Then
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.requestSize, 4)
        XCTAssertEqual(marker.responseSize, 123)
        XCTAssertTrue(marker.duration > 0)
        if case let .finished(responseCode) = marker.state {
            XCTAssertEqual(responseCode, 200)
        }
        else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finalizingMarker_withError_shouldRetainOriginalValues() {
        // Given
        let delegate = Delegate()
        let marker = HTTPMarker(url: .random, method: "b", delegate: delegate)
        let error = CocoaError(CocoaError.coderValueNotFound)

        // When
        wait(0.1)
        marker.ended(error: error, responseSize: 10)
        marker.ended(error: CocoaError(CocoaError.coderInvalidValue), responseSize: 20)
        marker.ended(responseCode: 300, responseSize: 321)

        // Then
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.responseSize, 10)
        XCTAssertTrue(marker.duration > 0)
        if case let .failed(e) = marker.state {
            XCTAssertEqual(e as? CocoaError, error)
        }
        else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finalizingMarker_withCancel_shouldRetainOriginalValues() {
        // Given
        let delegate = Delegate()
        let marker = HTTPMarker(url: .random, method: "b", delegate: delegate)

        // When
        wait(0.1)
        marker.canceled()
        marker.canceled()
        marker.ended(responseCode: 300, responseSize: 321)

        // Then
        XCTAssertEqual(delegate.finaliedCount, 1)
        XCTAssertEqual(marker.responseSize, 0)
        XCTAssertTrue(marker.duration > 0)
        if case .canceled = marker.state {} else {
            XCTFail("Wrong marker state: \(marker.state)")
        }
    }
    
    func test_finishedMarker_toBeaconConversion() {
        // Given
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "m", requestSize: 111, delegate: Delegate())
        marker.ended(responseCode: 204, responseSize: 10)


        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "m")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, 204)
        XCTAssertEqual(beacon.requestSize, 111)
        XCTAssertEqual(beacon.responseSize, 10)
        XCTAssertEqual(beacon.result, "finished")
    }
    
    func test_failedMarker_toBeaconConversion() {
        // Given
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "t", requestSize: 123, delegate: Delegate())
        let error = CocoaError(CocoaError.coderValueNotFound)
        marker.ended(error: error)

        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "t")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        XCTAssertEqual(beacon.requestSize, 123)
        XCTAssertEqual(beacon.responseSize, 0)
        XCTAssertEqual(beacon.result, String(describing: error as Error))
    }
    
    func test_canceledMarker_toBeaconConversion() {
        // Given
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "c", requestSize: 1, delegate: Delegate())
        marker.canceled()

        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, marker.duration)
        XCTAssertEqual(beacon.method, "c")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        XCTAssertEqual(beacon.requestSize, 1)
        XCTAssertEqual(beacon.responseSize, 0)
        XCTAssertEqual(beacon.result, "canceled")
    }
    
    func test_starteddMarker_toConversion() {
        // Given
        let url: URL = .random
        let marker = HTTPMarker(url: url, method: "c", requestSize: 1, delegate: Delegate())

        // When
        guard let beacon = marker.createBeacon() as? HTTPBeacon else {
            XCTFail("Beacon type missmatch"); return
        }

        // Then
        XCTAssertTrue(beacon.id.count > 0)
        XCTAssertEqual(beacon.timestamp, marker.startTime)
        XCTAssertEqual(beacon.duration, 0)
        XCTAssertEqual(beacon.method, "c")
        XCTAssertEqual(beacon.url, url)
        XCTAssertEqual(beacon.responseCode, -1)
        XCTAssertEqual(beacon.requestSize, 1)
        XCTAssertEqual(beacon.responseSize, 0)
        XCTAssertEqual(beacon.result, "started")
    }
}

extension URL {
    static var random: URL { URL(string: "http://www.example.com/\((0...100).randomElement() ?? 0)")! }
}

extension HTTPMarkerTests {
    class Delegate: HTTPMarkerDelegate {
        var finaliedCount: Int = 0
        func finalized(marker: HTTPMarker) {
            finaliedCount += 1
        }
    }
}
