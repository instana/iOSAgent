//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

/// Use this class when submitting user events to the Instana backend.
@objc public class CustomEventEvent: Event {
    public let name: String
    public let duration: Instana.Types.Milliseconds
    
    @objc public convenience init(name: String) {
        self.init(name: name, timestamp: Date().timeIntervalSince1970)
    }
    
    @objc public init(name: String, timestamp: Instana.Types.UTCTimestamp) {
        self.name = name
        self.duration = 0
        super.init(timestamp: timestamp)
    }
    
    @objc public init(name: String, timestamp: Instana.Types.UTCTimestamp, duration: Instana.Types.Milliseconds) {
        self.name = name
        self.duration = duration
        super.init(timestamp: timestamp)
    }
    
    override func toJSON() -> [String : Any] {
        var json = super.toJSON()
        json["event"] = [
            "timestamp": timestamp,
            "durationMs": duration,
            "customEvent": [
                "name": name
            ]
        ]
        return json
    }
}
