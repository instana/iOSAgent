import XCTest
@testable import InstanaAgent
import Network

class ReporterRateLimitTests: InstanaTestCase {

    func test_rateLimitReached_one() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 1)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        let result = limiter.canSubmit()

        // Then
        XCTAssertTrue(result)
    }

    func test_rateLimitReached_reached() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 1)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        var result = limiter.canSubmit()
        result = limiter.canSubmit()

        // Then
        XCTAssertFalse(result)
    }

    func test_rateLimitReached_zero_allowed() {
        // Given
        let configs: [InstanaConfiguration.ReporterRateLimitConfig] = [.init(timeout: 0.5, maxItems: 0)]
        let limiter = ReporterRateLimiter(configs: configs)

        // When
        let result = limiter.canSubmit()

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
        var result = limiter.canSubmit()
        // Fire another one AFTER the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout + 0.1) {
            result = limiter.canSubmit()
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
        var result = limiter.canSubmit()
        // Fire another one BEFORE the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout - 0.1) {
            result = limiter.canSubmit()
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
        var result = limiter.canSubmit()
        // Fire two AFTER the first limit has been cleared
        DispatchQueue.main.asyncAfter(deadline: .now() + firstTimeout + 0.1) {
            result = limiter.canSubmit()
            result = limiter.canSubmit()
            waitFor.fulfill()
        }
        wait(for: [waitFor], timeout: firstTimeout + 3)

        // Then
        XCTAssertFalse(result)
    }
}
