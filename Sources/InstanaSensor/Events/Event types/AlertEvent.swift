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
        super.init()
    }
}
