import Foundation

class AlertBeacon: Beacon {
    enum AlertType {
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
