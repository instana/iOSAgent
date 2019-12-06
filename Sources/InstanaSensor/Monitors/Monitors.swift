//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

class Monitors {

    var applicationNotResponding: ApplicationNotRespondingMonitor?
    var lowMemory: LowMemoryMonitor?
    var framerateDrop: FramerateDropMonitor?
    var http: HTTPMonitor?
    lazy var network = NetworkMonitor()
    private let configuration: InstanaConfiguration
    let reporter: Reporter

    init(_ configuration: InstanaConfiguration, reporter: Reporter) {
        self.configuration = configuration
        self.reporter = reporter
        configuration.monitorTypes.forEach { type in
            switch type {
            case .http:
                http = HTTPMonitor(configuration, reporter: reporter)
            case .memoryWarning:
                lowMemory = LowMemoryMonitor(reporter: reporter)
            case .framerateDrop(let threshold):
                framerateDrop = FramerateDropMonitor(threshold: threshold, reporter: reporter)
            case .alertApplicationNotResponding(let threshold):
                applicationNotResponding = ApplicationNotRespondingMonitor(threshold: threshold, reporter: reporter)
            }
        }
    }
}
