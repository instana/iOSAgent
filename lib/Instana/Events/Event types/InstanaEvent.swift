//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public protocol InstanaEvent {
    var sessionId: String { get }
    var eventId: String { get }
    var timestamp: Instana.Types.UTCTimestamp { get }
}

protocol InstanaInternalEvent: InstanaEvent {
    func toJSON() -> [String: Any]
}

enum InstanaEventResult {
    case success
    case failure(error: Error)
}

protocol InstanaEventResultNotifiable {
    typealias CompletionBlock = (_ result: InstanaEventResult) -> Void
    var completion: CompletionBlock { get }
}
