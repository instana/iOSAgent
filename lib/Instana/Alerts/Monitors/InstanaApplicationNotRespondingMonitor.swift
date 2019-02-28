//  Created by Nikola Lajic on 1/31/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaApplicationNotRespondingMonitor {
    // needed since Timer retains the target
    private class TimerProxy {
        weak var proxied: InstanaApplicationNotRespondingMonitor?
        
        init(proxied: InstanaApplicationNotRespondingMonitor) {
            self.proxied = proxied
        }
        
        @objc func onTimer(timer: Timer) {
            proxied?.onTimer(timer: timer)
        }
    }
    
    let submitEvent: InstanaEvents.Submitter
    var treshold: Instana.Types.Seconds
    private var timer: Timer?
    private let samplingInterval: Double
    
    private init() { fatalError() }
    
    init(treshold: Instana.Types.Seconds, samplingInterval: Double = 1.0, submitEvent: @escaping InstanaEvents.Submitter = Instana.events.submit(event:)) {
        self.submitEvent = submitEvent
        self.treshold = treshold
        self.samplingInterval = samplingInterval
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        scheduleTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
}

private extension InstanaApplicationNotRespondingMonitor {
    func scheduleTimer() {
        timer?.invalidate()
        let proxy = TimerProxy(proxied: self)
        let t = Timer(timeInterval: samplingInterval, target: proxy, selector: #selector(proxy.onTimer(timer:)), userInfo: CFAbsoluteTimeGetCurrent(), repeats: false)
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }
    
    @objc func onApplicationEnteredForeground() {
        scheduleTimer()
    }
    
    @objc func onApplicationEnteredBackground() {
        timer?.invalidate()
    }
    
    func onTimer(timer: Timer) {
        guard let start = timer.userInfo as? CFAbsoluteTime else {
            scheduleTimer()
            return
        }
        
        let delay = CFAbsoluteTimeGetCurrent() - start - samplingInterval
        if delay > treshold {
            let event = InstanaAlertEvent(alertType: .anr(duration: delay), screen: InstanaSystemUtils.viewControllersHierarchy())
            submitEvent(event)
        }
        scheduleTimer()
    }
}
