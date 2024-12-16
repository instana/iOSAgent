//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class ApplicationNotRespondingMonitor {
    var threshold: Instana.Types.Seconds
    private let reporter: Reporter
    var timer: Timer?
    private let samplingInterval: Double
    private init() { fatalError("Wrong init - Please use init(threshold: Instana.Types.Seconds, samplingInterval: Double, reporter: Reporter) instead") }

    init(threshold: Instana.Types.Seconds, samplingInterval: Double = 1.0, reporter: Reporter) {
        self.reporter = reporter
        self.threshold = threshold
        self.samplingInterval = samplingInterval

        InstanaApplicationStateHandler.shared.listen { [weak self] state, _ in
            guard let self = self else { return }
            if state == .active {
                self.scheduleTimer()
            } else {
                self.timer?.invalidate()
            }
        }

        scheduleTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func scheduleTimer() {
        timer?.invalidate()
        let aTimer = InstanaTimerProxy.timer(proxied: self, timeInterval: samplingInterval, userInfo: CFAbsoluteTimeGetCurrent(), repeats: false)
        timer = aTimer
        RunLoop.main.add(aTimer, forMode: .common)
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
            reporter.submit(AlertBeacon(alertType: .anr(duration: delay)))
        }
        scheduleTimer()
    }
}
