//  Created by Nikola Lajic on 1/31/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaApplicationNotRespondingMonitor {
    var treshold: Instana.Types.Seconds
    private var timer: Timer?
    private let samplingInterval = 1.0
    
    private init() { fatalError() }
    
    init(treshold: Instana.Types.Seconds) {
        self.treshold = treshold
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}

private extension InstanaApplicationNotRespondingMonitor {
    func scheduleTimer() {
        timer?.invalidate()
        let proxy = InstanaTimerProxy(delegate: self)
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
}

extension InstanaApplicationNotRespondingMonitor: InstanaTimerProxyDelegate {
    func onTimer(timer: Timer) {
        guard let start = timer.userInfo as? CFAbsoluteTime else {
            scheduleTimer()
            return
        }
        
        let delay = CFAbsoluteTimeGetCurrent() - start - samplingInterval
        if delay > treshold {
            let event = InstanaAlertEvent(alertType: .anr(duration: delay), screen: InstanaSystemUtils.viewControllersHierarchy())
            Instana.events.submit(event: event)
        }
        scheduleTimer()
    }
}

private protocol InstanaTimerProxyDelegate: class {
    func onTimer(timer: Timer)
}

private class InstanaTimerProxy {
    private weak var delegate: InstanaTimerProxyDelegate?
    init(delegate: InstanaTimerProxyDelegate) {
        self.delegate = delegate
    }
    @objc func onTimer(timer: Timer) {
        delegate?.onTimer(timer: timer)
    }
}
