//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class Monitors {
    var appLaunchMonitor: AppLaunchMonitor?
    var applicationNotResponding: ApplicationNotRespondingMonitor?
    var lowMemory: LowMemoryMonitor?
    var framerateDrop: FramerateDropMonitor?
    var metric: MetricMonitor?
    var http: HTTPMonitor?
    let reporter: Reporter
    private let session: InstanaSession
    private var startBeaconTriggered = false

    init(_ session: InstanaSession, reporter: Reporter? = nil) {
        self.session = session
        let reporter = reporter ?? Reporter(session)
        self.reporter = reporter
        session.configuration.monitorTypes.forEach { type in
            switch type {
            case .http:
                http = HTTPMonitor(session, reporter: reporter)
            case .appLaunchTime:
                appLaunchMonitor = AppLaunchMonitor(reporter: reporter)
            case .memoryWarning:
                lowMemory = LowMemoryMonitor(reporter: reporter)
            case let .framerateDrop(threshold):
                framerateDrop = FramerateDropMonitor(threshold: threshold, reporter: reporter)
            case let .alertApplicationNotResponding(threshold):
                applicationNotResponding = ApplicationNotRespondingMonitor(threshold: threshold, reporter: reporter)
            case .crash:
                subscribeCrashReporting()
            }
        }

        submitStartBeaconIfNeeded()
    }

    func subscribeCrashReporting() {
        guard metric == nil else {
            return
        }
        metric = MetricMonitor(session, reporter: reporter)
        metric!.convertDiagnosticsToBeacons()
    }

    func stopCrashReporting() {
        metric?.stopCrashReporting()
    }

    func cancelCrashReporting() -> Bool {
        guard let metric = self.metric else { return false }
        return metric.cancelDiagnosticReporting()
    }

    func submitStartBeaconIfNeeded() {
        if session.configuration.isValid, session.collectionEnabled, !startBeaconTriggered {
            reporter.submit(SessionProfileBeacon(state: .start))
            startBeaconTriggered = true
        }
    }
}
