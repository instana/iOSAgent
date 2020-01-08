import Foundation

class Monitors {
    var applicationNotResponding: ApplicationNotRespondingMonitor?
    var lowMemory: LowMemoryMonitor?
    var framerateDrop: FramerateDropMonitor?
    var http: HTTPMonitor?
    let reporter: Reporter
    private let environment: InstanaEnvironment

    init(_ environment: InstanaEnvironment, reporter: Reporter? = nil) {
        self.environment = environment
        let reporter = reporter ?? Reporter(environment)
        self.reporter = reporter
        environment.configuration.monitorTypes.forEach { type in
            switch type {
            case .http:
                http = HTTPMonitor(environment, reporter: reporter)
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
