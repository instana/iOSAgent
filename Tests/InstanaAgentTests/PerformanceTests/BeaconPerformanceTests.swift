//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class BeaconPerformanceTests: InstanaTestCase {

    var reporter: Reporter!

    func testCreateCoreBeacon() {
        // Given
        let beacon = createHTTPBeacon()
        let factory = CoreBeaconFactory(.mock)

        self.measure {
            // When
            guard let sut = try? factory.map(beacon) else {
                XCTFail("Could not map Beacon to CoreBeacon")
                return
            }

            // Then
            AssertTrue(Mirror(reflecting: sut).nonNilChildren.count > 0)
        }
    }

    func testSubmitCoreBeacons_1_time() {
        var done = false
        let waitFor = expectation(description: "testSubmitCoreBeacons_1_time")
        // Given
        reporter = Reporter(.mock(configuration: .mock), batterySafeForNetworking: { true }) { _, _ in
            if done { return }
            done = true
            waitFor.fulfill()
        }

        measure {
            // When
            reporter.submit(createHTTPBeacon())
        }

        // Then
        wait(for: [waitFor], timeout: 10.0)
        AssertTrue(done)
    }

    func testSubmitCoreBeacons_10_times() {
        var done = false
        let waitFor = expectation(description: "testSubmitCoreBeacons_10_times")
        let config = InstanaConfiguration.mock(debounce: 1.0)
        // Given
        reporter = Reporter(.mock(configuration: config), batterySafeForNetworking: { true }) { _, _ in
            done = true
            // Must fire only once since we have a debounce of one second
            waitFor.fulfill()
        }

        measure {
            // When
            (0..<10).forEach {_ in
                reporter.submit(createHTTPBeacon())
            }
        }

        // Then
        wait(for: [waitFor], timeout: 55.0)
        AssertTrue(done)
    }

    // Helper
    func createHTTPBeacon() -> HTTPBeacon {
        HTTPBeacon(timestamp: Date().millisecondsSince1970,
                   method: "POST",
                   url: URL.random,
                   header: nil,
                   responseCode: 0,
                   responseSize: HTTPMarker.Size(header: 4, body: 5, bodyAfterDecoding: 6),
                   error: nil,
                   backendTracingID: "BackendTID")
    }
}
