//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class AlertBeacon: Beacon {
    enum AlertType: Equatable {
        case anr(duration: Instana.Types.Seconds)
        case lowMemory
        case framerateDrop(duration: Instana.Types.Seconds, averageFramerate: Float)
    }

    let alertType: AlertType

    init(alertType: AlertType) {
        self.alertType = alertType
        super.init()
    }
}
