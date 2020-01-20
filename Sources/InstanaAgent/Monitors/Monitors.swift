import Foundation

class Monitors {
    var applicationNotResponding: ApplicationNotRespondingMonitor?
    var lowMemory: LowMemoryMonitor?
    var framerateDrop: FramerateDropMonitor?
    var http: HTTPMonitor?
    let reporter: Reporter
    private let session: InstanaSession

    init(_ session: InstanaSession, reporter: Reporter? = nil) {
        self.session = session
        let reporter = reporter ?? Reporter(session)
        self.reporter = reporter
        session.configuration.monitorTypes.forEach { type in
            switch type {
            case .http:
                http = HTTPMonitor(session, reporter: reporter)
            case .memoryWarning:
                lowMemory = LowMemoryMonitor(reporter: reporter)
            case let .framerateDrop(threshold):
                framerateDrop = FramerateDropMonitor(threshold: threshold, reporter: reporter)
            case let .alertApplicationNotResponding(threshold):
                applicationNotResponding = ApplicationNotRespondingMonitor(threshold: threshold, reporter: reporter)
            }
        }
    }
}
