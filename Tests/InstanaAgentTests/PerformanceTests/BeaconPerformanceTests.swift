import Foundation
import XCTest
@testable import InstanaAgent

class BeaconPerformanceTests: XCTestCase {

    var reporter: Reporter!

    func testCreateCoreBeacon() {
        // Given
        let beacon = createHTTPBeacon()
        let mapper = CoreBeaconFactory(.mock)

        self.measure {
            // When
            guard let sut = try? mapper.map(beacon) else {
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
        reporter = Reporter(.mock(configuration: .default(key: "KEY")), batterySafeForNetworking: { true }) { _, _ in
            done = true
            waitFor.fulfill()
        }

        self.measure {
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

        // Given
        reporter = Reporter(.mock(configuration: .default(key: "KEY")), batterySafeForNetworking: { true }) { _, _ in
            done = true
            waitFor.fulfill()
        }

        self.measure {
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
                   responseCode: 0,
                   responseSize: Instana.Types.HTTPSize(header: 4, body: 5, bodyAfterDecoding: 6),
                   error: nil,
                   backendTracingID: "BackendTID")
    }
}
