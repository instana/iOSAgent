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
            } else if state == .inactive, oldState == .background {
                // Application.willEnterForegroundNotification
                self.warmStartBeginTime = CFAbsoluteTimeGetCurrent()
            }
        }
    }

    func reportAppLaunchTime() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if prewarm != nil {
            // report cold start time
            let launchTimePostMain = currentTime - appPostMainStartTime
            var launchTimePreMain: CFAbsoluteTime?
            let processStartTime = ImageTracker.retrieveObjCLoadTime()
            if processStartTime > 0, processStartTime < appPostMainStartTime {
                launchTimePreMain = currentTime - processStartTime
            }
            // reporter?.submit(<coldStartTrue>, launchTimePreMain, launchTimePostMain, prewarm)
        } else if warmStartBeginTime != nil {
            // report warm start time
            let launchTimeWarm = currentTime - warmStartBeginTime!
            // reporter?.submit(<coldStartFalse>, launchTimeWarm)
        } else {
            // hot start
        }
        // prepare for next round app launch time (warm start) measurement
        prewarm = nil
        warmStartBeginTime = nil
    }
}
