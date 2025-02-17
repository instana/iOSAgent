//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class ApplicationNotRespondingMonitor {
    var anrDetector: Detector?
    var threshold: Instana.Types.Seconds
    private let reporter: Reporter
    private let samplingInterval: Double
    private init() { fatalError("Wrong init - Please use init(threshold: Instana.Types.Seconds, samplingInterval: Double, reporter: Reporter) instead") }

    @Atomic private var isRunning = false
    private var semaphore = DispatchSemaphore(value: 0)

    init(threshold: Instana.Types.Seconds, samplingInterval: Double = 1.0, reporter: Reporter) {
        self.reporter = reporter
        self.threshold = threshold
        self.samplingInterval = samplingInterval

        InstanaApplicationStateHandler.shared.listen { [weak self] state, _ in
            guard let self = self else { return }
            if state == .active {
                if self.anrDetector == nil {
                    anrDetector = Detector(anrMonitor: self)
                    anrDetector?.start(threshold: threshold, samplingInterval: samplingInterval)
                }
            } else if state == .background {
                self.anrDetector?.stop()
                self.anrDetector = nil
            }
        }

        anrDetector = Detector(anrMonitor: self)
        anrDetector?.start(threshold: threshold, samplingInterval: samplingInterval)
    }

    class Detector {
        weak var anrMonitor: ApplicationNotRespondingMonitor?
        @Atomic private var isRunning = false
        private var semaphore = DispatchSemaphore(value: 0)

        init(anrMonitor: ApplicationNotRespondingMonitor?) {
            self.anrMonitor = anrMonitor
        }

        func start(threshold: Instana.Types.Seconds, samplingInterval: Double) {
            guard !isRunning else { return }
            isRunning = true

            DispatchQueue.global(qos: .background).async { [weak self] in
                while self?.isRunning == true {
                    let startTime = CFAbsoluteTimeGetCurrent()

                    DispatchQueue.main.async {
                        self?.semaphore.signal()
                    }

                    let result = self?.semaphore.wait(timeout: .now() + threshold)

                    if self?.isRunning != true {
                        break
                    }

                    if result == .timedOut {
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        self?.anrMonitor?.reporter.submit(PerfAppNotRespondingBeacon(duration: duration))
                    }

                    Thread.sleep(forTimeInterval: samplingInterval)
                }
            }
        }

        func stop() {
            isRunning = false
        }
    }
}
