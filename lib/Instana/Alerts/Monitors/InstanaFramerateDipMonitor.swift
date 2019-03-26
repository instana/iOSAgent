//  Created by Nikola Lajic on 2/4/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaFramerateDipMonitor {
    // needed since CADisplayLink retains the target
    private class DisplayLinkProxy {
        weak var proxied: InstanaFramerateDipMonitor?
        @objc func onDisplayLinkUpdate() {
            proxied?.onDisplayLinkUpdate()
        }
    }
    
    private let submitEvent: InstanaEvents.Submitter
    private let threshold: UInt
    private let displayLink: CADisplayLink
    private let samplingInterval: Instana.Types.Seconds
    private var samplingStart: CFTimeInterval = 0
    private var elapsedFrames: UInt = 0
    private var dipStart: CFAbsoluteTime?
    private var runningAverage: Float = 0
    private var consecutiveFrameDip: UInt = 0
    
    private init() { fatalError() }
    
    init(threshold: UInt, samplingInterval: Instana.Types.Seconds = 1, submitEvent: @escaping InstanaEvents.Submitter = Instana.events.submit(event:)) {
        self.submitEvent = submitEvent
        self.samplingInterval = samplingInterval
        self.threshold = threshold
        let proxy = DisplayLinkProxy()
        displayLink = CADisplayLink(target: proxy, selector: #selector(proxy.onDisplayLinkUpdate))
        proxy.proxied = self
        displayLink.add(to: RunLoop.main, forMode: .common)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        displayLink.invalidate()
    }
}

private extension InstanaFramerateDipMonitor {

    @objc func onApplicationEnteredForeground() {
        displayLink.isPaused = false
    }
    
    @objc func onApplicationEnteredBackground() {
        displayLink.isPaused = true
        dipStart = nil
        samplingStart = 0
        elapsedFrames = 0
    }
}

private extension InstanaFramerateDipMonitor {
    func onDisplayLinkUpdate() {
        guard samplingStart > 0 else {
            samplingStart = displayLink.timestamp
            return
        }
        
        elapsedFrames += 1
        let samplingDuration = displayLink.timestamp - samplingStart
        
        if samplingDuration > samplingInterval {
            handle(fps: UInt(round(Double(elapsedFrames) / samplingDuration)))
            samplingStart = 0
            elapsedFrames = 0
        }
    }
    
    func handle(fps: UInt) {
        switch (fps < threshold, dipStart) {
        case (true, nil):
            dipStart = samplingStart
            runningAverage = Float(fps)
            consecutiveFrameDip = 1
        case (true, _?):
            consecutiveFrameDip += 1
            runningAverage -= runningAverage / Float(consecutiveFrameDip)
            runningAverage += Float(fps) / Float(consecutiveFrameDip)
        case (false, let start?):
            let duration = displayLink.timestamp - start
            let event = InstanaAlertEvent(alertType: .framerateDip(duration: duration, averageFramerate: runningAverage), screen: InstanaSystemUtils.viewControllersHierarchy())
            submitEvent(event)
            dipStart = nil
            runningAverage = 0
            consecutiveFrameDip = 0
        default:
            break
        }
    }
}
