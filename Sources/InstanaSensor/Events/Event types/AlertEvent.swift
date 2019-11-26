//  Created by Nikola Lajic on 1/31/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class AlertEvent: Event {
    enum AlertType {
        case anr(duration: Instana.Types.Seconds)
        case lowMemory
        case framerateDrop(duration: Instana.Types.Seconds, averageFramerate: Float)
    }
    let alertType: AlertType
    private let screen: String?
    
    init(alertType: AlertType, screen: String?) {
        self.alertType = alertType
        self.screen = screen
        super.init(timestamp: Date().timeIntervalSince1970)
    }
    
    override func toJSON() -> [String : Any] {
        var json = super.toJSON()
        var alert: [String: Any] = ["timestamp": timestamp]
        var body: [String: Any] = [:]
        body.set(ifNotNil: screen, forKey: "screen")
        
        switch alertType {
        case .framerateDrop(let duration, let average):
            body["durationMs"] = duration * 1000
            body["averageFramerate"] = average
            alert["framerateDrop"] = body
        case .lowMemory:
            alert["lowMemory"] = body
        case .anr(let duration):
            body["durationMs"] = duration * 1000
            alert["anr"] = body
        }

        json["alert"] = alert
        return json
    }
}
