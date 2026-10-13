//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent

///
/// Root object for the InstanaSessionReplay package
///
@available(iOS 13.0, *)
public class InstanaSessionReplay: NSObject {
    let config: InstanaSessionReplayConfig
    let stagingManager: StagingManager
    let screenCapture: ScreenCapture
    var maskedViews: [WeakRef<UIView>] = []
    let userEvent: UserEvent
    let notificationObserver: NotificationObserver
    // Pause/Resume state management
    var isPausedState: Bool = true

    static var current: InstanaSessionReplay?

    @objc
    public static func setup(config: InstanaSessionReplayConfig?, autoStart: Bool) throws {
        try setupInternal(config: config, autoStart: autoStart)
    }

    @objc
    public static func setup(config: InstanaSessionReplayConfig?) throws {
        try setupInternal(config: config, autoStart: true)
    }

    @objc
    public static func setup() throws {
        try setupInternal()
    }

    /**
     * Resumes session recording
     * Only works if recording was previously paused
     */
    @objc
    public static func resumeRecording() {
        InstanaSessionReplay.current?.resumeRecording()
    }

    /**
     * Pauses session recording
     * Can be called by host app to temporarily stop recording
     * This will pause both image capture AND action beacons
     * Recording can be resumed with resumeRecording()
     */
    @objc
    public static func pauseRecording() {
        InstanaSessionReplay.current?.pauseRecording()
    }

    @objc
    public static func isRecordingPaused() -> Bool {
        return InstanaSessionReplay.current?.isRecordingPaused() == true
    }

    @objc
    public static func maskView(_ view: UIView) {
        InstanaSessionReplay.current?.maskView(view)
    }

    @objc
    public static func unmaskView(_ view: UIView) {
        InstanaSessionReplay.current?.unmaskView(view)
    }

    @objc public static func flushSessionReplayData() {
        InstanaSessionReplay.current?.flushSessionReplayData()
    }

    /**
     * This pauses image capture in session replay, but action beacons will still be sent.
     */
    @objc public static func pauseImageCapture() {
        InstanaSessionReplay.current?.pauseImageCapture()
    }

    /**
     * This resumes image capture in session replay, but action beacons will still be sent.
     */
    @objc public static func resumeImageCapture() {
        InstanaSessionReplay.current?.resumeImageCapture()
    }

    internal init(config: InstanaSessionReplayConfig, activeWindowProvider: ActiveWindowProvider? = nil) throws {
        self.config = config

        // Make sampling decision at initialization time
        let sessionId = SessionSampler.getEffectiveSessionId(sessionId: Instana.sessionID)
        self.config.isSampled = SessionSampler.shouldRecordSession(sessionId: sessionId,
                        samplingPercentage: self.config.samplingConfig.samplingPercentage)
        if self.config.isSampled {
            Instana.log("Session Replay: Session SAMPLED for recording (sampling rate: \(self.config.samplingConfig.samplingPercentage), sessionId: \(sessionId))", level: .debug)
        } else {
            Instana.log("Session Replay: Session NOT sampled (sampling rate: \(self.config.samplingConfig.samplingPercentage), sessionId: \(sessionId))", level: .debug)
        }

        stagingManager = try StagingManager(config: self.config)
        screenCapture = ScreenCapture(config: self.config, stagingManager: self.stagingManager, windowProvider: activeWindowProvider)

        userEvent = UserEvent(config: self.config, stagingManager: stagingManager)
        notificationObserver = NotificationObserver(stagingManager: stagingManager)

        super.init()
        screenCapture.sessionReplay = self
        userEvent.notificationObserver = notificationObserver
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLowMemoryWarning(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onRuntimeConfigurationUpdated(_:)),
            name: .runtimeConfigurationUpdated,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .runtimeConfigurationUpdated, object: nil)
    }

    @objc func onLowMemoryWarning(_ notification: Notification) {
        screenCapture.onLowMemory()
    }

    @objc func onRuntimeConfigurationUpdated(_ notification: Notification) {
        guard let newConfig = notification.object as? RuntimeConfiguration else {
            return
        }
        Instana.log("Session Replay: runtime configuration updated: \(newConfig)", level: .debug)
        DispatchQueue.main.async { [weak self] in
            if self?.config.syncWithServerConfiguration(serverConfig: newConfig) == true {
                self?.applyConfiguration()
            }
        }
    }

    private static func setupInternal(config: InstanaSessionReplayConfig? = nil,
                                      autoStart: Bool = true,
                                      activeWindowProvider: ActiveWindowProvider? = nil) throws {
        guard InstanaSessionReplay.current == nil else { return }
        guard Instana.current != nil else {
            throw InstanaError.notInitialized
        }

        Instana.stepUpRateLimits(.MID_LIMITS)
        UIApplication.setupSwizzle()

        // merge server side configuration with agent side configuration
        let copiedConfig = (config ?? InstanaSessionReplayConfig()).copy() as! InstanaSessionReplayConfig
        _ = copiedConfig.syncWithServerConfiguration(serverConfig: Instana.getRuntimeConfiguration())

        let srInstance = try InstanaSessionReplay(config: copiedConfig, activeWindowProvider: activeWindowProvider)
        InstanaSessionReplay.current = srInstance

        srInstance.setSessionReplayStatus()

        if autoStart {
            srInstance.resumeRecording()
        }
        if srInstance.config.isTrackingEnabled() {
            FrequentRestart.checkForForceKill()
        }
    }

    private func resumeRecording() {
        // no need to track any data
        guard config.isTrackingEnabled() else { return }

        guard isPausedState else { return }
        isPausedState = false

        UIApplication.toggleSwizzle(true)
        notificationObserver.startObserving()
        resumeImageCapture()
    }

    private func pauseRecording() {
        guard !isPausedState else { return }
        isPausedState = true

        UIApplication.toggleSwizzle(false)
        notificationObserver.stopObserving()
        screenCapture.stopCapture()
    }

    private func isRecordingPaused() -> Bool {
        return isPausedState
    }

    private func maskView(_ view: UIView) {
        guard config.isTrackingEnabled() else { return }
        guard config.maskStrategy == .mask_sensitive else { return }
        maskedViews.append(WeakRef(view))
    }

    private func unmaskView(_ view: UIView) {
        guard config.isTrackingEnabled() else { return }
        guard config.maskStrategy == .mask_sensitive else { return }
        maskedViews.removeAll{ $0.value === view }
    }

    private func flushSessionReplayData() {
        // manual flush is only supported in onDemandSampling and relevantSampling
        if config.isSampled { return }
        stagingManager.flushSessionReplayData()
    }

    private func pauseImageCapture() {
        // prevent sr status gets set to an impossible value
        guard config.isTrackingEnabled() else { return }

        screenCapture.stopCapture()
        Instana.setSrStatus(status: "1")
    }

    private func resumeImageCapture() {
        // no need to capture image if tracking is not enabled for this session
        guard config.isTrackingEnabled() else { return }

        guard config.enableImageCapture else { return }
        screenCapture.startCapture()
        Instana.setSrStatus(status: "0")
    }

    func setSessionReplayStatus() {
        var status = "2"  //session replay not sampled
        if config.isTrackingEnabled() {
            // 0 → SR enabled: image + action beacon
            // 1 → SR enabled: action beacon only (no images)
            status = config.enableImageCapture ? "0" : "1"
        }
        Instana.setSrStatus(status: status)
    }

    private func applyConfiguration() {
        if config.disabledByServer {
            // clean up previous session replay data
            pauseRecording()
        } else {
            resumeRecording()
        }
        setSessionReplayStatus()
    }
}


@available(iOS 13.0, *)
extension InstanaSessionReplay {

    internal func retrieveMaskedUIViews() -> [UIView] {
        var newMaskedViews: [WeakRef<UIView>] = []
        var uiViews: [UIView] = []

        for wrapped in maskedViews {
            if let view = wrapped.value {
                newMaskedViews.append(wrapped)
                if view.window != nil {
                    uiViews.append(view)
                }
            }
        }
        if newMaskedViews.count != maskedViews.count {
            maskedViews = newMaskedViews
        }
        return uiViews
    }

    internal func processSendEvent(_ event: UIEvent) {
        userEvent.processSendEvent(event: event)
    }

    internal func processSendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) {
        userEvent.processSendAction(action, to: target, from: sender, for: event)
    }
}
