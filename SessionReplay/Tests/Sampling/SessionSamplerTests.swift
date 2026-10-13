//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay

class SessionSamplerTests: XCTestCase {

    // MARK: - shouldRecordSession: boundary percentages

    func test_shouldRecordSession_100Percent_alwaysReturnsTrue() {
        // Any session ID must be recorded when sampling is 100%
        XCTAssertTrue(SessionSampler.shouldRecordSession(sessionId: "any-session-id", samplingPercentage: 100))
        XCTAssertTrue(SessionSampler.shouldRecordSession(sessionId: "", samplingPercentage: 100))
    }

    func test_shouldRecordSession_0Percent_alwaysReturnsFalse() {
        // No session ID must be recorded when sampling is 0%
        XCTAssertFalse(SessionSampler.shouldRecordSession(sessionId: "any-session-id", samplingPercentage: 0))
        XCTAssertFalse(SessionSampler.shouldRecordSession(sessionId: "", samplingPercentage: 0))
    }

    // MARK: - shouldRecordSession: deterministic hash-based sampling

    func test_shouldRecordSession_isDeterministic_sameSessionId_sameResult() {
        // The same session ID must always produce the same sampling decision
        let sessionId = "deterministic-session-id-abc123"
        let firstResult = SessionSampler.shouldRecordSession(sessionId: sessionId, samplingPercentage: 50)
        let secondResult = SessionSampler.shouldRecordSession(sessionId: sessionId, samplingPercentage: 50)
        XCTAssertEqual(firstResult, secondResult)
    }

    func test_shouldRecordSession_isSampling_acrossManyIDs_approximatesExpectedRate() {
        // With 50% sampling over many deterministic IDs, roughly ~50% should be sampled.
        // We use a generous tolerance to avoid flakiness (hash distribution may not be perfectly uniform).
        let total = 1000
        var sampledCount = 0
        for i in 0..<total {
            let sessionId = "session-\(i)"
            if SessionSampler.shouldRecordSession(sessionId: sessionId, samplingPercentage: 50) {
                sampledCount += 1
            }
        }
        let rate = Double(sampledCount) / Double(total)
        XCTAssertTrue(rate > 0.30 && rate < 0.70, "Expected ~50% sampling rate, got \(rate * 100)%")
    }

    func test_shouldRecordSession_differentSessionIds_canProduceDifferentResults() {
        // Two different session IDs may produce different results at an intermediate percentage.
        // We iterate until we find a pair to confirm it is NOT always constant.
        var foundDifferent = false
        for i in 0..<1000 {
            let a = SessionSampler.shouldRecordSession(sessionId: "session-a-\(i)", samplingPercentage: 50)
            let b = SessionSampler.shouldRecordSession(sessionId: "session-b-\(i)", samplingPercentage: 50)
            if a != b {
                foundDifferent = true
                break
            }
        }
        XCTAssertTrue(foundDifferent, "Expected different session IDs to occasionally produce different sampling decisions")
    }

    func test_shouldRecordSession_highPercentage_recordsMostSessions() {
        // 90% sampling should record the vast majority of sessions
        let total = 200
        var sampledCount = 0
        for i in 0..<total {
            if SessionSampler.shouldRecordSession(sessionId: "session-\(i)", samplingPercentage: 90) {
                sampledCount += 1
            }
        }
        let rate = Double(sampledCount) / Double(total)
        XCTAssertTrue(rate > 0.70, "Expected >70% sampling at 90%, got \(rate * 100)%")
    }

    func test_shouldRecordSession_lowPercentage_recordsFewSessions() {
        // 10% sampling should record only a small fraction of sessions
        let total = 200
        var sampledCount = 0
        for i in 0..<total {
            if SessionSampler.shouldRecordSession(sessionId: "session-\(i)", samplingPercentage: 10) {
                sampledCount += 1
            }
        }
        let rate = Double(sampledCount) / Double(total)
        XCTAssertTrue(rate < 0.30, "Expected <30% sampling at 10%, got \(rate * 100)%")
    }

    // MARK: - shouldRecordSession: nil / empty sessionId fallback

    func test_shouldRecordSession_emptySessionId_doesNotCrash() {
        // Empty string falls through to hash-based sampling; must not crash
        let result = SessionSampler.shouldRecordSession(sessionId: "", samplingPercentage: 50)
        XCTAssertTrue(result == true || result == false)
    }

    // MARK: - getEffectiveSessionId

    func test_getEffectiveSessionId_validSessionId_returnsAsIs() {
        let sessionId = "valid-session-id-123"
        XCTAssertEqual(SessionSampler.getEffectiveSessionId(sessionId: sessionId), sessionId)
    }

    func test_getEffectiveSessionId_nilSessionId_returnsGeneratedUUID() {
        let result = SessionSampler.getEffectiveSessionId(sessionId: nil)
        // Must be a valid UUID string
        XCTAssertNotNil(UUID(uuidString: result), "Expected a valid UUID string for nil sessionId, got: \(result)")
    }

    func test_getEffectiveSessionId_emptySessionId_returnsGeneratedUUID() {
        let result = SessionSampler.getEffectiveSessionId(sessionId: "")
        XCTAssertNotNil(UUID(uuidString: result), "Expected a valid UUID string for empty sessionId, got: \(result)")
    }

    func test_getEffectiveSessionId_nilSessionId_generatesDifferentUUIDEachCall() {
        // Each call with nil should produce a fresh, unique UUID
        let first = SessionSampler.getEffectiveSessionId(sessionId: nil)
        let second = SessionSampler.getEffectiveSessionId(sessionId: nil)
        XCTAssertNotEqual(first, second, "Expected different UUIDs for successive nil calls")
    }

    func test_getEffectiveSessionId_emptySessionId_generatesDifferentUUIDEachCall() {
        let first = SessionSampler.getEffectiveSessionId(sessionId: "")
        let second = SessionSampler.getEffectiveSessionId(sessionId: "")
        XCTAssertNotEqual(first, second, "Expected different UUIDs for successive empty-string calls")
    }

    func test_getEffectiveSessionId_whitespaceOnlySessionId_returnsAsIs() {
        // Whitespace is non-empty, so it should be returned unchanged
        let whitespace = "   "
        XCTAssertEqual(SessionSampler.getEffectiveSessionId(sessionId: whitespace), whitespace)
    }
}
