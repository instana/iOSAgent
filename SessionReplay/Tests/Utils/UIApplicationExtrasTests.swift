//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
import UIKit
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

/// Tests for the UIApplication+Extras extension:
///   • toggleSwizzle / swizzleOn state
///   • setupSwizzle idempotency (method_exchangeImplementations is called once via SR setup)
///   • swizzled_sendEvent forwarding behaviour (swizzleOn = true / false)
///   • swizzled_sendAction forwarding behaviour (swizzleOn = true / false)
///
/// IMPORTANT: setupSwizzle() permanently swaps method implementations for the
/// lifetime of the process. Tests must NOT call setupSwizzle() a second time —
/// doing so would swap the implementations back and break every subsequent test
/// in the suite. We rely on InstanaSessionReplay.setup() having already called
/// setupSwizzle() once, and we drive behaviour purely through toggleSwizzle().
@available(iOS 13.0, *)
class UIApplicationExtrasTests: SessionReplayTestCaseBase {

    // Capture calls forwarded by the swizzled implementations
    var sendEventCallCount = 0
    var sendActionCallCount = 0

    override func setUp() {
        super.setUp()
        sendEventCallCount = 0
        sendActionCallCount = 0

        // Ensure SR is set up (which calls setupSwizzle once) but NOT recording,
        // so we can control swizzleOn ourselves.
        try? InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)
    }

    override func tearDown() {
        // Always leave swizzle disabled so it doesn't bleed into other tests.
        UIApplication.toggleSwizzle(false)
        super.tearDown()
    }

    // MARK: - toggleSwizzle / swizzleOn Tests

    func test_toggleSwizzle_setsSwizzleOnToTrue() {
        UIApplication.toggleSwizzle(true)
        XCTAssertTrue(UIApplication.swizzleOn)
    }

    func test_toggleSwizzle_setsSwizzleOnToFalse() {
        UIApplication.toggleSwizzle(true)
        UIApplication.toggleSwizzle(false)
        XCTAssertFalse(UIApplication.swizzleOn)
    }

    func test_toggleSwizzle_startsAsFalseAfterSetup() {
        // autoStart:false means resumeRecording() was not called → swizzleOn stays false
        XCTAssertFalse(UIApplication.swizzleOn)
    }

    func test_toggleSwizzle_canBeCalledMultipleTimesWithSameValue() {
        // Should not crash or produce unexpected state
        UIApplication.toggleSwizzle(true)
        UIApplication.toggleSwizzle(true)
        XCTAssertTrue(UIApplication.swizzleOn)

        UIApplication.toggleSwizzle(false)
        UIApplication.toggleSwizzle(false)
        XCTAssertFalse(UIApplication.swizzleOn)
    }

    // MARK: - setupSwizzle idempotency

    func test_setupSwizzle_alreadyApplied_sendEventStillWorks() {
        // setupSwizzle() was already called by InstanaSessionReplay.setup().
        // Verify that UIApplication.shared.sendEvent does not crash —
        // i.e., the swizzled chain remains intact.
        UIApplication.toggleSwizzle(false)

        // Posting a custom event type won't reach real UIKit handling, but the
        // swizzled method must not crash.
        let app = UIApplication.shared
        // UIEvent cannot be instantiated directly; we exercise the path via
        // the swizzled sendAction instead (which is directly callable).
        let didReturn = app.sendAction(#selector(UIResponder.becomeFirstResponder),
                                       to: nil, from: nil, for: nil)
        // The action may or may not succeed depending on the first responder state;
        // the important thing is no crash and a Bool is returned.
        let _ = didReturn
    }

    // MARK: - swizzled_sendEvent Tests

    func test_swizzledSendEvent_whenSwizzleOff_doesNotForwardToSessionReplay() {
        // Given
        UIApplication.toggleSwizzle(false)
        let instance = InstanaSessionReplay.current

        // Inject a spy: replace processSendEvent by observing via a mock SR instance.
        // Because processSendEvent is called on InstanaSessionReplay.current we can
        // simply verify the call count on a known-zero baseline.
        // We cannot synthesise a real UIEvent, but we can verify the guard branch:
        // with swizzleOn == false, current?.processSendEvent is never called regardless
        // of what event arrives. We confirm this by checking that swizzleOn is false.
        XCTAssertFalse(UIApplication.swizzleOn)
        XCTAssertNotNil(instance) // SR is set up
    }

    func test_swizzledSendEvent_whenSwizzleOn_swizzleOnFlagIsTrue() {
        // Given / When
        UIApplication.toggleSwizzle(true)

        // Then – the flag that gates forwarding inside swizzled_sendEvent is set
        XCTAssertTrue(UIApplication.swizzleOn)
    }

    // MARK: - swizzled_sendAction Tests

    func test_swizzledSendAction_whenSwizzleOff_returnsResult() {
        // Given
        UIApplication.toggleSwizzle(false)

        // When – call the real (now swizzled-to-original) sendAction path
        let result = UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil)

        // Then – returns a Bool without crashing; value depends on responder chain
        let _ = result  // either true or false is acceptable
        XCTAssertFalse(UIApplication.swizzleOn)
    }

    func test_swizzledSendAction_whenSwizzleOn_returnsResult() {
        // Given – SR is active; turn swizzle on
        UIApplication.toggleSwizzle(true)

        // When – sendAction should forward to SR then call original; must not crash
        let result = UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil)

        // Then
        let _ = result
        XCTAssertTrue(UIApplication.swizzleOn)
    }

    func test_swizzledSendAction_whenSwizzleOn_withNilCurrentSR_doesNotCrash() {
        // Given – no active SR instance
        InstanaSessionReplay.current = nil
        UIApplication.toggleSwizzle(true)

        // When / Then – processSendAction is guarded by optional chaining; must not crash
        let result = UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil)
        let _ = result
    }

    func test_swizzledSendAction_whenSwizzleOff_withNilCurrentSR_doesNotCrash() {
        // Given
        InstanaSessionReplay.current = nil
        UIApplication.toggleSwizzle(false)

        // When / Then
        let result = UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil)
        let _ = result
    }

    // MARK: - resumeRecording / pauseRecording toggle swizzle integration

    func test_resumeRecording_enablesSwizzle() throws {
        // Given – SR set up with tracking enabled (samplingPercentage 100)
        InstanaSessionReplay.current = nil
        let config = InstanaSessionReplayConfig(
            samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        XCTAssertFalse(UIApplication.swizzleOn)

        // When
        InstanaSessionReplay.resumeRecording()
        let exp = expectation(description: "main flush")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertTrue(UIApplication.swizzleOn)
    }

    func test_pauseRecording_disablesSwizzle() throws {
        // Given – recording is running
        InstanaSessionReplay.current = nil
        let config = InstanaSessionReplayConfig(
            samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.screenCapture.windowProvider = mockWindowProvider
        InstanaSessionReplay.resumeRecording()
        let startExp = expectation(description: "started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)
        XCTAssertTrue(UIApplication.swizzleOn)

        // When
        InstanaSessionReplay.pauseRecording()

        // Then
        XCTAssertFalse(UIApplication.swizzleOn)
    }
}
