//
//  File.swift
//
//
//  Created by Christian Menschel on 01.12.21.
//

import Foundation

class ReporterRateLimiter {
    class Limiter {
        let maxItems: Int
        let timeout: TimeInterval
        var current = 0
        private lazy var queue = DispatchQueue(label: "com.instana.ios.agent.reporterratelimit.\(maxItems).\(timeout)")

        var exceeds: Bool { current > maxItems }

        init(maxItems: Int, timeout: TimeInterval) {
            self.maxItems = maxItems
            self.timeout = timeout
            scheduleReset()
        }

        func scheduleReset() {
            queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self = self else { return }
                self.current = 0
                self.scheduleReset()
            }
        }

        func signal() -> Bool {
            queue.sync {
                current += 1
                return exceeds
            }
        }
    }

    let limiters: [Limiter]

    init(configs: [InstanaConfiguration.ReporterRateLimitConfig]) {
        limiters = configs.map { Limiter(maxItems: $0.maxItems, timeout: $0.timeout) }
    }

    func canSubmit(_ beacon: Beacon) -> Bool {
        if beacon is SessionProfileBeacon || beacon is DiagnosticBeacon {
            // DiagnosticBeacon and SessionProfileBeacon can always be submitted
            return true
        }
        return limiters.map { $0.signal() }.filter { $0 == true }.isEmpty
    }
}
