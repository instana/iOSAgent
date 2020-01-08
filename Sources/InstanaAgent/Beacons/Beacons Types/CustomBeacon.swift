import Foundation

/// Use this class when submitting user beacons to the Instana backend.
class CustomBeacon: Beacon {
    public let name: String
    public let duration: Instana.Types.Milliseconds

    init(name: String, duration: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.name = name
        self.duration = duration
        super.init()
    }
}
