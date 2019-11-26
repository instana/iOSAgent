//  Created by Nikola Lajic on 1/31/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import UIKit

class ApplicationNotRespondingMonitor {
    var threshold: Instana.Types.Seconds
    private let submitter: EventReporter.Submitter
    private var timer: Timer?
    private let samplingInterval: Double
    
    private init() { fatalError() }
    
    init(threshold: Instana.Types.Seconds, samplingInterval: Double = 1.0, submitter: @escaping EventReporter.Submitter = Instana.eventReporter.submit(_:)) {
        self.submitter = submitter
        self.threshold = threshold
        self.samplingInterval = samplingInterval
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        scheduleTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
}

private extension ApplicationNotRespondingMonitor {
    func scheduleTimer() {
        timer?.invalidate()
        let t = InstanaTimerProxy.timer(proxied: self, timeInterval: samplingInterval, userInfo: CFAbsoluteTimeGetCurrent(), repeats: false)
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }
    
    @objc func onApplicationEnteredForeground() {
        scheduleTimer()
    }
    
    @objc func onApplicationEnteredBackground() {
        timer?.invalidate()
    }
    
}

extension ApplicationNotRespondingMonitor: InstanaTimerProxiedTarget {
    func onTimer(timer: Timer) {
        guard let start = timer.userInfo as? CFAbsoluteTime else {
            scheduleTimer()
            return
        }
        
        let delay = CFAbsoluteTimeGetCurrent() - start - samplingInterval
        if delay > threshold {
            submitter(AlertEvent(alertType: .anr(duration: delay), screen: InstanaSystemUtils.viewControllersHierarchy()))
        }
        scheduleTimer()
    }
}
