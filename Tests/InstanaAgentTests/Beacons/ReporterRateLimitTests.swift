import XCTest
@testable import InstanaAgent
import Network

class ReporterRateLimitTests: InstanaTestCase {
    private let sessionBeacon = SessionProfileBeacon(state: .start)
    private let crashBeacon = DiagnosticBeacon(crashSession:
                         PreviousSession(id: UUID(),
                         startTime: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!,
                         viewName: "mockViewName",
                         carrier: "mockCarrier",
                         connectionType: "mockConnectionType",
                         userID: "mockUserID",
                         userEmail: "mockEmail",
                         userName: "mockUserName"),
                               crashGroupID: UUID(),
                               crashType: .crash,
                               crashTime: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!.millisecondsSince1970,
                               duration: 0,
                               crashPayload: "",
                               formatted: "",
                               errorType: "",
                               errorMessage: "",
                               isSymbolicated: false)
    // following beacons are rate limited
    private let httpBeacon = HTTPBeacon(method: "GET", url:URL(string: "https://www.ibm.com")!, responseCode: 200)
    private let customBeacon = CustomBeacon(name: "TestCustomBeacon1")
    private let viewChangeBeacon = ViewChange(viewName: "TestView1")
    private let alertBeacon = PerformanceBeacon(subType: .lowMemory)

    func test_rateLimitReached_one() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 1)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        let result = limiter.canSubmit(customBeacon)

        // Then
        XCTAssertTrue(result)
    }

    func test_rateLimitReached_reached() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 1)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        var result = limiter.canSubmit(customBeacon)
        result = limiter.canSubmit(customBeacon)

        // Then
        XCTAssertFalse(result)

        // More
        XCTAssertFalse(limiter.canSubmit(httpBeacon))
        XCTAssertFalse(limiter.canSubmit(viewChangeBeacon))
        XCTAssertFalse(limiter.canSubmit(alertBeacon))
        XCTAssertTrue(limiter.canSubmit(sessionBeacon))
        XCTAssertTrue(limiter.canSubmit(crashBeacon))
    }

    func test_rateLimitReached_zero_allowed() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 0)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        let result = limiter.canSubmit(customBeacon)

        // Then
        XCTAssertFalse(result)
    }

    func test_rateLimitReached_multiple_valid_second_limit() {
        // Given
        let firstTimeout = 0.5
        let waitFor = expectation(description: "test_rateLimitReached_multiple_not_reached")
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: firstTimeout, maxItems: 1),
                                                                       .init(timeout: 1.0, maxItems: 2)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        var result = limiter.canSubmit(customBeacon)
        // Fire another one AFTER the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout + 0.1) {
            result = limiter.canSubmit(self.customBeacon)
            waitFor.fulfill()
        }
        wait(for: [waitFor], timeout: firstTimeout + 3)

        // Then
        XCTAssertTrue(result)
    }

    func test_rateLimitReached_multiple_not_cleared_first_limit() {
        // Given
        let firstTimeout = 0.5
        let waitFor = expectation(description: "test_rateLimitReached_multiple_not_reached")
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: firstTimeout, maxItems: 1),
                                                                       .init(timeout: 1.0, maxItems: 2)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        var result = limiter.canSubmit(customBeacon)
        // Fire another one BEFORE the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout - 0.1) {
            result = limiter.canSubmit(self.customBeacon)
            waitFor.fulfill()
        }
        wait(for: [waitFor], timeout: firstTimeout + 3)

        // Then
        XCTAssertFalse(result)
    }

    func test_rateLimitReached_multiple_no_valid_limit_available() {
        // Given
        let firstTimeout = 0.5
        let waitFor = expectation(description: "test_rateLimitReached_multiple_not_reached")
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: firstTimeout, maxItems: 1),
                                                                       .init(timeout: 1.0, maxItems: 2)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        var result = limiter.canSubmit(customBeacon)
        // Fire two AFTER the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout + 0.1) {
            result = limiter.canSubmit(self.customBeacon)
            result = limiter.canSubmit(self.customBeacon)
            waitFor.fulfill()
        }
        wait(for: [waitFor], timeout: firstTimeout + 3)

        // Then
        XCTAssertFalse(result)
    }
}
