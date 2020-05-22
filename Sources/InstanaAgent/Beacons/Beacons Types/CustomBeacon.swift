//
//  File.swift
//
//
//  Created by Christian Menschel on 07.05.20.
//

import Foundation


// An identifier for using the current visible view name as default instead of nil - we need to set the current visible view later in the reporting process pipeline
public let CustomBeaconDefaultViewNameID = UUID().uuidString

class CustomBeacon: Beacon {
    let name: String
    let duration: Instana.Types.Milliseconds?
    let backendTracingID: String?
    let error: Error?
    let meta: [String: String]?

    init(timestamp: Instana.Types.Milliseconds? = nil,
         name: String,
         duration: Instana.Types.Milliseconds? = nil,
         backendTracingID: String? = nil,
         error: Error? = nil,
         meta: [String: String]? = nil,
         viewName: String? = CustomBeaconDefaultViewNameID) {
        self.duration = duration
        self.name = name
        self.error = error
        self.meta = meta
        self.backendTracingID = backendTracingID
        var start = Date().millisecondsSince1970
        if let duration = duration {
            start -= duration
        }
        if let timestamp = timestamp {
            start = timestamp
        }
        super.init(timestamp: start, viewName: viewName)
    }
}
