//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaSessionProfileEvent: InstanaInternalEvent, InstanaEventResultNotifiable {
    let sessionId: String = Instana.sessionId
    let eventId: String = ""
    let timestamp: Instana.Types.UTCTimestamp = 0
    var completion: CompletionBlock {
        get { return handleCompletion }
    }
    private let maxRetryInterval = 30_000
    private var retryInterval = 50 {
        didSet {
            if retryInterval > maxRetryInterval { retryInterval = maxRetryInterval }
        }
    }
    
    func toJSON() -> [String : Any] {
        let sessionProfile = [
            "platform": "iOS",
            "osLevel": UIDevice.current.systemVersion,
            "osDistro": "Apple",
            "deviceType": UIDevice.current.modelName,
            "appVersion": Bundle.main.versionNumber ?? "unknown-version",
            "appBuild": Bundle.main.buildNumber ?? "unknown-build"
        ]
        return [
            "sessionId": sessionId,
            "sessionProfile": sessionProfile
        ]
    }
}

private extension InstanaSessionProfileEvent {
    func handleCompletion(result: InstanaEventResult) -> Void {
        switch result {
        case .success:
            Instana.log.add("Session profile sent")
        case .failure(_):
            Instana.log.add("Failed to send session profile. Retrying in \(retryInterval) ms.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(retryInterval)) {
                Instana.events.submit(event: self)
            }
            retryInterval *= 2
        }
    }
}

private extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

private extension Bundle {
    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

