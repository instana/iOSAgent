//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

// swiftlint:disable:next
// An identifier for using the current visible view name as default instead of nil - we need to set the current visible view later in the reporting process pipeline
// swiftlint:disable:next identifier_name
public let CustomBeaconDefaultViewNameID = UUID().uuidString

class CustomBeacon: Beacon {
    let name: String
    let duration: Instana.Types.Milliseconds?
    let backendTracingID: String?
    let error: Error?
    let metaData: MetaData?
    let customMetric: Double?
    let eventType: String? // internal meta

    init(timestamp: Instana.Types.Milliseconds? = nil,
         name: String,
         duration: Instana.Types.Milliseconds? = nil,
         backendTracingID: String? = nil,
         error: Error? = nil,
         metaData: MetaData? = nil,
         viewName: String? = CustomBeaconDefaultViewNameID,
         customMetric: Double? = nil,
         eventType: String? = nil) {
        self.duration = duration
        self.name = name
        self.error = error
        self.metaData = metaData
        self.backendTracingID = backendTracingID
        var start = Date().millisecondsSince1970
        if let duration = duration {
            start -= duration
        }
        if let timestamp = timestamp {
            start = timestamp
        }
        self.customMetric = customMetric
        self.eventType = eventType
        super.init(timestamp: start, viewName: viewName)
    }

    override func extractDropBeaconValues() -> CustomEventDropBeacon {
        return CustomEventDropBeacon(timestamp: timestamp, eventName: name, view: viewName,
                                     errorCount: (error != nil) ? 1 : nil,
                                     errorMessage: (error != nil) ? "\(error!.localizedDescription)" : nil,
                                     customMetric: (customMetric != nil) ? "\(customMetric!)" : nil)
    }
}
