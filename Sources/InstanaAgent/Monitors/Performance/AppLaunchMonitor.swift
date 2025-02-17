//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

#if SWIFT_PACKAGE
    import ImageTracker
#endif

class AppLaunchMonitor {
    weak var reporter: Reporter?
    var appPostMainStartTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    var prewarm: Bool?
    var warmStartBeginTime: CFTimeInterval?
    var hotStartBeginTime: CFTimeInterval?

    init(reporter: Reporter) {
        self.reporter = reporter

        prewarm = false
        if let prewarmFlagStr = ProcessInfo.processInfo.environment["ActivePrewarm"] {
            if let prewarmFlagInt = Int(prewarmFlagStr), prewarmFlagInt > 0 {
                prewarm = true
            }
        }

        InstanaApplicationStateHandler.shared.listen { [weak self] state, oldState in
            guard let self = self else { return }
            if state == .active {
                // Application.didBecomeActiveNotification
                self.reportAppLaunchTime()
            } else if state == .inactive {
                // Application.willEnterForegroundNotification
                if oldState == .background {
                    self.warmStartBeginTime = CFAbsoluteTimeGetCurrent()
                } else {
                    self.hotStartBeginTime = CFAbsoluteTimeGetCurrent()
                }
            }
        }
    }

    func reportAppLaunchTime() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if prewarm != nil {
            // report cold start time
            let launchTimePostMain: Double = currentTime - appPostMainStartTime
            var launchTimePreMain: Double?
            let processStartTime = ImageTracker.retrieveObjCLoadTime()
            if processStartTime > 0, processStartTime < appPostMainStartTime {
                launchTimePreMain = Double(currentTime - processStartTime)
            }
            let launchTimeCold = launchTimePreMain ?? launchTimePostMain
            reporter?.submit(PerfAppLaunchBeacon(appColdStartTime: Int(Double(launchTimeCold) * 1000.0)))
        } else if warmStartBeginTime != nil {
            // report warm start time
            let launchTimeWarm = currentTime - warmStartBeginTime!
            reporter?.submit(PerfAppLaunchBeacon(appWarmStartTime: Int(Double(launchTimeWarm) * 1000.0)))
        } else if hotStartBeginTime != nil {
            // report hot start time
            let launchTimeHot = currentTime - hotStartBeginTime!
            reporter?.submit(PerfAppLaunchBeacon(appHotStartTime: Int(Double(launchTimeHot) * 1000.0)))
        }

        // prepare for next round app launch time (warm start) measurement
        prewarm = nil
        warmStartBeginTime = nil
        hotStartBeginTime = nil
    }
}
