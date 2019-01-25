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
            "osDistro": "Apple",
            "osLevel": InstanaSystemUtils.systemVersion,
            "deviceType": InstanaSystemUtils.deviceModel,
            "appVersion": InstanaSystemUtils.applicationVersion,
            "appBuild": InstanaSystemUtils.applicationBuildNumber
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

