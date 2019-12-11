//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public enum ReportingType: Int {
    /// Both automatic and manual calls will be reported
    case automaticAndManual
    /// Only automatic calls will be reported
    case automatic
    /// Only manual calls will be reported
    case manual
    /// Ignore all calls
    case none
}

struct InstanaConfiguration {

    enum SuspendReporting {
        /// Reporting is suspended while the device battery is low.
        case lowBattery
        /// Reporting is suspended while the device is using a cellular connection.
        case cellularConnection

        static let defaults: Set<SuspendReporting> = []
    }

    enum MonitorTypes: Hashable {
        case http
        case memoryWarning
        case framerateDrop(frameThreshold: UInt)
        case alertApplicationNotResponding(threshold: Instana.Types.Seconds)

        static let defaults: Set<MonitorTypes> = [.http,
                                                  .memoryWarning,
                                                  .framerateDrop(frameThreshold: 20),
                                                  .alertApplicationNotResponding(threshold: 2.0)]
    }

    struct Defaults {
        static let reporterURL = URL(string: "http://localhost:3000")!
        static let transmissionDelay: Instana.Types.Seconds = 1.0
        static let transmissionLowBatteryDelay: Instana.Types.Seconds = 10.0
        static let gzipReport = true
    }


    var reportingURL: URL
    var key: String
    var reportingType: ReportingType
    var suspendReporting: Set<SuspendReporting>
    var monitorTypes: Set<MonitorTypes>
    var transmissionDelay: Instana.Types.Seconds
    var transmissionLowBatteryDelay: Instana.Types.Seconds
    var gzipReport: Bool
    var isValid: Bool { !key.isEmpty && !reportingURL.absoluteString.isEmpty }

    static var empty: InstanaConfiguration {
        .default(key: "", reportingURL: nil, reportingType: .none)
    }

    static func `default`(key: String, reportingURL: URL? = nil, reportingType: ReportingType = .automaticAndManual) -> InstanaConfiguration {
        self.init(reportingURL: reportingURL ?? Defaults.reporterURL,
                  key: key,
                  reportingType: reportingType,
                  suspendReporting: SuspendReporting.defaults,
                  monitorTypes: MonitorTypes.defaults,
                  transmissionDelay: Defaults.transmissionDelay,
                  transmissionLowBatteryDelay: Defaults.transmissionLowBatteryDelay,
                  gzipReport: Defaults.gzipReport
        )
    }
}
