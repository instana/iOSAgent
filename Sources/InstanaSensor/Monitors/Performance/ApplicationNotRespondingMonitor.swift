import Foundation
import UIKit

class ApplicationNotRespondingMonitor {
    var threshold: Instana.Types.Seconds
    private let reporter: Reporter
    private var timer: Timer?
    private let samplingInterval: Double
    private init() { fatalError() }

    init(threshold: Instana.Types.Seconds, samplingInterval: Double = 1.0, reporter: Reporter) {
        self.reporter = reporter
        self.threshold = threshold
        self.samplingInterval = samplingInterval
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredForeground),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationEnteredBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        scheduleTimer()
    }

    deinit {
        timer?.invalidate()
    }
}

private extension ApplicationNotRespondingMonitor {
    func scheduleTimer() {
        timer?.invalidate()
        let aTimer = InstanaTimerProxy.timer(proxied: self, timeInterval: samplingInterval, userInfo: CFAbsoluteTimeGetCurrent(), repeats: false)
        timer = aTimer
        RunLoop.main.add(aTimer, forMode: .common)
    }

    @objc func onApplicationEnteredForeground() {
        scheduleTimer()
    }

    @objc  func onApplicationEnteredBackground() {
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
            reporter.submit(AlertBeacon(alertType: .anr(duration: delay)))
        }
        scheduleTimer()
    }
}
