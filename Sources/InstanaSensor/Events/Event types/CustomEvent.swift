//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

/// Use this class when submitting user events to the Instana backend.
@objc public class CustomEvent: Event {
    public let name: String
    public let duration: Instana.Types.Milliseconds
    
    @objc public convenience init(name: String) {
        self.init(name: name, timestamp: Date().millisecondsSince1970)
    }
    
    @objc public init(name: String,
                      timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.name = name
        self.duration = 0
        super.init(timestamp: timestamp)
    }
    
    @objc public init(name: String,
                      timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
                      duration: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.name = name
        self.duration = duration
        super.init(timestamp: timestamp)
    }
    
//    override func toJSON() -> [String : Any] {
//        var json = super.toJSON()
//        json["event"] = [
//            "timestamp": timestamp,
//            "durationMs": duration,
//            "customEvent": [
//                "name": name
//            ]
//        ]
//        return json
//    }
}
