//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaCustomEvent: NSObject, InstanaEvent {
    public let sessionId: String = Instana.sessionId
    public let eventId: String = UUID().uuidString
    public let timestamp: Instana.Types.UTCTimestamp
    public let name: String
    public let duration: Instana.Types.Milliseconds?
    
    @objc public convenience init(name: String) {
        self.init(name: name, timestamp: Date().timeIntervalSince1970)
    }
    
    @objc public init(name: String, timestamp: Instana.Types.UTCTimestamp) {
        self.name = name
        self.timestamp = timestamp
        self.duration = nil
        super.init()
    }
    
    @objc public init(name: String, timestamp: Instana.Types.UTCTimestamp, duration: Instana.Types.Milliseconds) {
        self.name = name
        self.timestamp = timestamp
        self.duration = duration
        super.init()
    }
}

extension InstanaCustomEvent: InstanaInternalEvent {
    func toJSON() -> [String : Any] {
        var event: [String: Any] = [
            "timestamp": timestamp,
            "customEvent": [
                "name": name
            ]
        ]
        if let duration = duration {
            event["durationMs"] = duration
        }
        return [
            "sessionId": sessionId,
            "id": eventId,
            "event": event
        ]
    }
}
