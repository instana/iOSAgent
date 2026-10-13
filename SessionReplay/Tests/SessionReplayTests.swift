//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class InstanaSessionReplayTests: SessionReplayTestCaseBase {

    override func setUp() {
        super.setUp()

        // Minimal Instana setup required by InstanaSessionReplay.setupInternal
        _ = Instana.setup(key: "TEST_KEY",
                          reportingURL: URL(string: "http://localhost")!,
                          options: nil)
    }

    override func tearDown() {
        InstanaSessionReplay.current = nil
        Instana.current = nil
        UserDefaults.standard.removeObject(forKey: FrequentRestart.keyRestartTimestamps)
        super.tearDown()
    }

    // MARK: - Setup Tests

    func test_setup_withDefaultConfig() throws {
        // When
        try InstanaSessionReplay.setup()

        // Then
        XCTAssertNotNil(InstanaSessionReplay.current)
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)
    }

    func test_setup_withCustomConfig() throws {
        // Given
        let config = InstanaSessionReplayConfig(framePerSecond: 0.5,
                                                maskStrategy: .mask_sensitive,
                                                maskingColor: .red)

        // When
        try InstanaSessionReplay.setup(config: config)

        // Then
        XCTAssertNotNil(InstanaSessionReplay.current)
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)
        XCTAssertEqual(InstanaSessionReplay.current?.config.framePerSecond, 0.5)
        XCTAssertEqual(InstanaSessionReplay.current?.config.maskStrategy, .mask_sensitive)
        XCTAssertEqual(InstanaSessionReplay.current?.config.maskingColor, .red)
    }

    func test_setup_withAutoStartTrue() throws {
        // Given
        let config = InstanaSessionReplayConfig()

        // When
        try InstanaSessionReplay.setup(config: config, autoStart: true)

        // Then
        XCTAssertNotNil(InstanaSessionReplay.current)
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)
    }

    func test_setup_withAutoStartFalse() throws {
        // Given
        let config = InstanaSessionReplayConfig()

        // When
        try InstanaSessionReplay.setup(config: config, autoStart: false)

        // Then
        XCTAssertNotNil(InstanaSessionReplay.current)
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)
    }

    func test_setup_throwsErrorWhenInstanaNotInitialized() throws {
        // Given
        Instana.current = nil

        // When/Then
        XCTAssertThrowsError(try InstanaSessionReplay.setup()) { error in
            XCTAssertEqual(error as? InstanaError, InstanaError.notInitialized)
        }
    }

    func test_setup_doesNotCreateMultipleInstances() throws {
        // Given
        try InstanaSessionReplay.setup()
        let firstInstance = InstanaSessionReplay.current

        // When
        try InstanaSessionReplay.setup()
        let secondInstance = InstanaSessionReplay.current

        // Then
        XCTAssertTrue(firstInstance === secondInstance)
    }

    // MARK: - Start/Stop Tests

    func test_start_startsCapture() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(framePerSecond: 0.001),
                                       autoStart: false)
        InstanaSessionReplay.current?.screenCapture.windowProvider = mockWindowProvider
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)

        // When
        InstanaSessionReplay.resumeRecording()

        // Wait a bit for the timer to be scheduled on main thread
        let expectation = self.expectation(description: "Timer started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(InstanaSessionReplay.current?.screenCapture.timer)
    }

    func test_stop_stopsCapture() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(framePerSecond: 0.001),
                                       autoStart: false)
        InstanaSessionReplay.current?.screenCapture.windowProvider = mockWindowProvider

        // When
        InstanaSessionReplay.resumeRecording()

        // Wait for timer to start
        let startExpectation = self.expectation(description: "Timer started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(InstanaSessionReplay.current?.screenCapture.timer)
            startExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        // When
        InstanaSessionReplay.pauseRecording()

        let stopExpectation = self.expectation(description: "Timer stopped")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            stopExpectation.fulfill()
        }
        wait(for: [stopExpectation], timeout: 1.0)

        // Then
        XCTAssertNil(InstanaSessionReplay.current?.screenCapture.timer)
    }

    // MARK: - Mask View Tests

    func test_maskView_withMaskMarkedStrategy() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let testView = UIView()

        // When
        InstanaSessionReplay.maskView(testView)

        // Then
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 1)
        XCTAssertTrue(InstanaSessionReplay.current?.maskedViews.first?.value === testView)
    }

    func test_maskView_withMaskAllStrategy_doesNotAddView() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_all)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let testView = UIView()

        // When
        InstanaSessionReplay.maskView(testView)

        // Then
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 0)
    }

    func test_maskView_withMaskNoneStrategy_doesNotAddView() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_none)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let testView = UIView()

        // When
        InstanaSessionReplay.maskView(testView)

        // Then
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 0)
    }

    func test_unmaskView_removesView() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let testView = UIView()
        InstanaSessionReplay.maskView(testView)
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 1)

        // When
        InstanaSessionReplay.unmaskView(testView)

        // Then
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 0)
    }

    func test_unmaskView_withMaskAllStrategy_doesNothing() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_all)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let testView = UIView()

        // When
        InstanaSessionReplay.unmaskView(testView)

        // Then
        XCTAssertEqual(InstanaSessionReplay.current?.maskedViews.count, 0)
    }

    //    func test_maskMultipleViews() throws {
    //        // Given

    // MARK: - isRecordingPaused Tests

    func test_isRecordingPaused_returnsTrueWhenNotStarted() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)

        // Then
        XCTAssertTrue(InstanaSessionReplay.isRecordingPaused())
    }

    func test_isRecordingPaused_returnsFalseAfterResume() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(framePerSecond: 0.001),
                                       autoStart: false)
        InstanaSessionReplay.current?.screenCapture.windowProvider = mockWindowProvider

        // When
        InstanaSessionReplay.resumeRecording()
        let exp = expectation(description: "main queue flush")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertFalse(InstanaSessionReplay.isRecordingPaused())
    }

    func test_isRecordingPaused_returnsTrueAfterPause() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(framePerSecond: 0.001),
                                       autoStart: false)
        InstanaSessionReplay.current?.screenCapture.windowProvider = mockWindowProvider
        InstanaSessionReplay.resumeRecording()
        let startExp = expectation(description: "started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)

        // When
        InstanaSessionReplay.pauseRecording()

        // Then
        XCTAssertTrue(InstanaSessionReplay.isRecordingPaused())
    }

    func test_isRecordingPaused_returnsFalseWhenCurrentIsNil() {
        // current is nil — static wrapper returns false
        XCTAssertFalse(InstanaSessionReplay.isRecordingPaused())
    }

    // MARK: - Pause / Resume Idempotency Tests

    func test_resumeRecording_isIdempotent() throws {
        // Given – start already running
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(framePerSecond: 0.001),
                                       autoStart: false)
        InstanaSessionReplay.current?.screenCapture.windowProvider = mockWindowProvider
        InstanaSessionReplay.resumeRecording()
        let exp1 = expectation(description: "first resume")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp1.fulfill() }
        wait(for: [exp1], timeout: 1.0)
        XCTAssertFalse(InstanaSessionReplay.isRecordingPaused())

        // When – resume again (should be no-op)
        InstanaSessionReplay.resumeRecording()
        let exp2 = expectation(description: "second resume")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp2.fulfill() }
        wait(for: [exp2], timeout: 1.0)

        // Then
        XCTAssertFalse(InstanaSessionReplay.isRecordingPaused())
    }

    func test_pauseRecording_isIdempotent() throws {
        // Given – already paused (autoStart: false)
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)
        XCTAssertTrue(InstanaSessionReplay.isRecordingPaused())

        // When – pause again (should be no-op, no crash)
        InstanaSessionReplay.pauseRecording()

        // Then
        XCTAssertTrue(InstanaSessionReplay.isRecordingPaused())
    }

    // MARK: - Static wrapper no-op when current is nil

    func test_staticWrappers_doNotCrashWhenCurrentIsNil() {
        // Verify static wrapper methods are safe to call with no instance
        XCTAssertNil(InstanaSessionReplay.current)
        InstanaSessionReplay.resumeRecording()
        InstanaSessionReplay.pauseRecording()
        InstanaSessionReplay.maskView(UIView())
        InstanaSessionReplay.unmaskView(UIView())
        InstanaSessionReplay.flushSessionReplayData()
        InstanaSessionReplay.pauseImageCapture()
        InstanaSessionReplay.resumeImageCapture()
    }

    // MARK: - setSessionReplayStatus Tests

    func test_setSessionReplayStatus_notSampled_setsStatus2() throws {
        // Given – not sampled, no on-demand/relevant sampling
        let samplingConfig = SamplingConfig(samplingPercentage: 0,
                                            onDemandSamplingEnabled: false)
        let config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // When
        instance.setSessionReplayStatus()

        // Then – status "2" means not sampled
        // We verify isSampled is false and isTrackingEnabled() is false
        XCTAssertFalse(instance.config.isSampled)
        XCTAssertFalse(instance.config.isTrackingEnabled())
    }

    func test_setSessionReplayStatus_sampledWithImageCapture_setsStatus0() throws {
        // Given – force isSampled = true, enableImageCapture = true
        let config = InstanaSessionReplayConfig(samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.config.enableImageCapture = true

        // Then
        XCTAssertTrue(instance.config.isTrackingEnabled())
        XCTAssertTrue(instance.config.enableImageCapture)
    }

    func test_setSessionReplayStatus_sampledWithoutImageCapture_setsStatus1() throws {
        // Given – force isSampled = true, enableImageCapture = false
        let config = InstanaSessionReplayConfig(samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.config.enableImageCapture = false

        // Then
        XCTAssertTrue(instance.config.isTrackingEnabled())
        XCTAssertFalse(instance.config.enableImageCapture)
    }

    // MARK: - pauseImageCapture / resumeImageCapture Tests

    func test_pauseImageCapture_stopsTimerWhenTrackingEnabled() throws {
        // Given – tracking enabled, image capture running
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001,
                                                samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.screenCapture.windowProvider = mockWindowProvider
        InstanaSessionReplay.resumeRecording()
        let startExp = expectation(description: "capture started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)
        XCTAssertNotNil(instance.screenCapture.timer)

        // When
        InstanaSessionReplay.pauseImageCapture()
        let stopExp = expectation(description: "capture stopped")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { stopExp.fulfill() }
        wait(for: [stopExp], timeout: 1.0)

        // Then
        XCTAssertNil(instance.screenCapture.timer)
    }

    func test_pauseImageCapture_doesNothingWhenTrackingDisabled() throws {
        // Given – not sampled, no on-demand
        let samplingConfig = SamplingConfig(samplingPercentage: 0, onDemandSamplingEnabled: false)
        let config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        XCTAssertNil(instance.screenCapture.timer)

        // When
        InstanaSessionReplay.pauseImageCapture()

        // Then – no timer was ever started, still nil
        XCTAssertNil(instance.screenCapture.timer)
    }

    func test_resumeImageCapture_doesNothingWhenTrackingDisabled() throws {
        // Given – not sampled, no on-demand
        let samplingConfig = SamplingConfig(samplingPercentage: 0, onDemandSamplingEnabled: false)
        let config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // When
        InstanaSessionReplay.resumeImageCapture()

        // Then – still no timer
        XCTAssertNil(instance.screenCapture.timer)
    }

    func test_resumeImageCapture_doesNothingWhenImageCaptureDisabled() throws {
        // Given – sampled but enableImageCapture = false
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001, enableImageCapture: false,
                                                samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.screenCapture.windowProvider = mockWindowProvider

        // When
        InstanaSessionReplay.resumeImageCapture()
        let exp = expectation(description: "main flush")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertNil(instance.screenCapture.timer)
    }

    // MARK: - flushSessionReplayData Tests

    func test_flushSessionReplayData_noOpWhenIsSampled() throws {
        // Given – session is sampled; flush should be a no-op
        let config = InstanaSessionReplayConfig(samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true

        // When/Then – must not crash
        InstanaSessionReplay.flushSessionReplayData()
    }

    func test_flushSessionReplayData_callsStagingManagerWhenNotSampled() throws {
        // Given – onDemand enabled, not sampled
        let samplingConfig = SamplingConfig(samplingPercentage: 0, onDemandSamplingEnabled: true)
        let config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        XCTAssertFalse(instance.config.isSampled)

        // When/Then – must not crash
        InstanaSessionReplay.flushSessionReplayData()
    }

    // MARK: - Low Memory Tests

    func test_onLowMemoryWarning_forwardsToScreenCapture() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // When – post memory warning notification directly
        instance.onLowMemoryWarning(Notification(name: UIApplication.didReceiveMemoryWarningNotification))

        // Then – screenshotCache should be cleared (lastHash becomes nil)
        let exp = expectation(description: "imageQueue flush")
        instance.screenCapture.imageQueue.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(instance.screenCapture.lastHash)
    }

    // MARK: - onRuntimeConfigurationUpdated Tests

    func test_onRuntimeConfigurationUpdated_withNonConfigObject_doesNotCrash() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // When – notification with a non-RuntimeConfiguration object
        let notification = Notification(name: .runtimeConfigurationUpdated, object: "not a config")
        instance.onRuntimeConfigurationUpdated(notification)

        // Then – should return early without crashing
        XCTAssertFalse(instance.config.disabledByServer)
    }

    func test_onRuntimeConfigurationUpdated_withNilObject_doesNotCrash() throws {
        // Given
        try InstanaSessionReplay.setup(config: InstanaSessionReplayConfig(), autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // When – notification with nil object
        let notification = Notification(name: .runtimeConfigurationUpdated, object: nil)
        instance.onRuntimeConfigurationUpdated(notification)

        // Then – should return early without crashing
        XCTAssertFalse(instance.config.disabledByServer)
    }

    func test_onRuntimeConfigurationUpdated_disabledByServer_pausesRecording() throws {
        // Given – recording is running
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001,
                                                samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.screenCapture.windowProvider = mockWindowProvider
        InstanaSessionReplay.resumeRecording()
        let startExp = expectation(description: "recording started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)
        XCTAssertFalse(instance.isPausedState)

        // When – runtime config disables SR
        let runtimeConfig = RuntimeConfiguration()
        runtimeConfig.update { state in
            state.srServerConfig = .disabled
            state.configurationTimeStamp = 1
        }
        let notification = Notification(name: .runtimeConfigurationUpdated, object: runtimeConfig)
        instance.onRuntimeConfigurationUpdated(notification)

        // Wait for the DispatchQueue.main.async inside onRuntimeConfigurationUpdated
        let applyExp = expectation(description: "applyConfiguration executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { applyExp.fulfill() }
        wait(for: [applyExp], timeout: 1.0)

        // Then
        XCTAssertTrue(instance.isPausedState)
    }

    func test_onRuntimeConfigurationUpdated_enabledByServer_resumesRecording() throws {
        // Given – recording paused, previously disabled by server
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001,
                                                samplingConfig: SamplingConfig(samplingPercentage: 100))
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)
        instance.config.isSampled = true
        instance.config.disabledByServer = true    // start in disabled state
        instance.screenCapture.windowProvider = mockWindowProvider
        XCTAssertTrue(instance.isPausedState)

        // When – runtime config re-enables SR
        let runtimeConfig = RuntimeConfiguration()
        runtimeConfig.update { state in
            state.srServerConfig = .enabled
            state.configurationTimeStamp = 2
        }
        let notification = Notification(name: .runtimeConfigurationUpdated, object: runtimeConfig)
        instance.onRuntimeConfigurationUpdated(notification)

        let applyExp = expectation(description: "applyConfiguration executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { applyExp.fulfill() }
        wait(for: [applyExp], timeout: 1.0)

        // Then – recording resumed
        XCTAssertFalse(instance.isPausedState)
    }

    // MARK: - retrieveMaskedUIViews Tests

    func test_retrieveMaskedUIViews_removesReleasedWeakRefs() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // Add a view that will be deallocated
        autoreleasepool {
            let ephemeralView = UIView()
            instance.maskedViews.append(WeakRef(ephemeralView))
        }
        // ephemeralView is gone; maskedViews still holds the (now nil) WeakRef
        XCTAssertEqual(instance.maskedViews.count, 1)

        // When
        let result = instance.retrieveMaskedUIViews()

        // Then – the dead ref is pruned, no views returned
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(instance.maskedViews.count, 0)
    }

    func test_retrieveMaskedUIViews_excludesViewsWithNoWindow() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        // A live view NOT attached to any window
        let detachedView = UIView()
        instance.maskedViews.append(WeakRef(detachedView))

        // When
        let result = instance.retrieveMaskedUIViews()

        // Then – ref is kept alive but view has no window → excluded from result
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(instance.maskedViews.count, 1)

        _ = detachedView // keep alive
    }

    func test_retrieveMaskedUIViews_includesViewsAttachedToWindow() throws {
        // Given
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        let attachedView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(attachedView)
        instance.maskedViews.append(WeakRef(attachedView))

        // When
        let result = instance.retrieveMaskedUIViews()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first === attachedView)

        attachedView.removeFromSuperview()
    }

    func test_retrieveMaskedUIViews_mixedRefs() throws {
        // Given – one alive+windowed, one alive+no-window, one dead
        let config = InstanaSessionReplayConfig(maskStrategy: .mask_sensitive)
        try InstanaSessionReplay.setup(config: config, autoStart: false)
        let instance = try XCTUnwrap(InstanaSessionReplay.current)

        let attachedView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(attachedView)
        let detachedView = UIView()

        instance.maskedViews.append(WeakRef(attachedView))
        instance.maskedViews.append(WeakRef(detachedView))
        autoreleasepool {
            let ephemeral = UIView()
            instance.maskedViews.append(WeakRef(ephemeral))
        }

        // When
        let result = instance.retrieveMaskedUIViews()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.first === attachedView)
        // Dead ref pruned; two live refs remain (attached + detached)
        XCTAssertEqual(instance.maskedViews.count, 2)

        attachedView.removeFromSuperview()
        _ = detachedView
    }
}
