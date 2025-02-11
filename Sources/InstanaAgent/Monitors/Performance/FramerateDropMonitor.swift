//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif

class FramerateDropMonitor {
    #if os(tvOS) || os(watchOS) || os(iOS)
        // needed since CADisplayLink retains the target
        private class DisplayLinkProxy {
            weak var proxied: FramerateDropMonitor?
            @objc func onDisplayLinkUpdate() {
                proxied?.onDisplayLinkUpdate()
            }
        }

        private let reporter: Reporter
        private let threshold: UInt
        private let displayLink: CADisplayLink
        private let samplingInterval: Instana.Types.Seconds
        private var samplingStart: CFTimeInterval = 0
        private var elapsedFrames: UInt = 0
        private var dropStart: CFAbsoluteTime?
        private var runningAverage: Float = 0
        private var consecutiveFrameDrop: UInt = 0

        private init() { fatalError("Wrong init - Please use init(threshold: UInt, samplingInterval: Instana.Types.Seconds, reporter: Reporter) instead") }

        init(threshold: UInt, samplingInterval: Instana.Types.Seconds = 1, reporter: Reporter) {
            self.reporter = reporter
            self.samplingInterval = samplingInterval
            self.threshold = threshold
            let proxy = DisplayLinkProxy()
            displayLink = CADisplayLink(target: proxy, selector: #selector(proxy.onDisplayLinkUpdate))
            proxy.proxied = self
            displayLink.add(to: .main, forMode: .default)

            InstanaApplicationStateHandler.shared.listen { [weak self] state, _ in
                guard let self = self else { return }
                if state == .active {
                    self.start()
                } else {
                    self.pause()
                }
            }
        }

        private func start() {
            displayLink.isPaused = false
        }

        private func pause() {
            displayLink.isPaused = true
            dropStart = nil
            samplingStart = 0
            elapsedFrames = 0
        }

        deinit {
            displayLink.invalidate()
        }

        @objc func onDisplayLinkUpdate() {
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
            switch (fps < threshold, dropStart) {
            case (true, nil):
                dropStart = samplingStart
                runningAverage = Float(fps)
                consecutiveFrameDrop = 1
            case (true, _):
                consecutiveFrameDrop += 1
                runningAverage -= runningAverage / Float(consecutiveFrameDrop)
                runningAverage += Float(fps) / Float(consecutiveFrameDrop)
            case (false, let start?):
                let duration = displayLink.timestamp - start
                reporter.submit(PerformanceBeacon(subType: .framerateDrop(duration: duration, averageFramerate: runningAverage)))
                dropStart = nil
                runningAverage = 0
                consecutiveFrameDrop = 0
            default:
                break
            }
        }

    #else
        init(threshold: UInt, samplingInterval: Instana.Types.Seconds = 1, reporter: Reporter) {}
    #endif
}
