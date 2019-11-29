//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class SessionProfileEvent: Event, EventResultNotifiable {

    enum State {
        case start
        case end
    }

    var completion: CompletionBlock {
        get { return handleCompletion }
    }
    private let maxRetryInterval: Instana.Types.Milliseconds = 30_000
    private var retryInterval: Instana.Types.Milliseconds {
        didSet {
            if retryInterval > maxRetryInterval { retryInterval = maxRetryInterval }
        }
    }
    private let submitter: BeaconReporter.Submitter
    let state: State

    init(state: State,
         retryInterval: Instana.Types.Milliseconds = 50,
         submitter: @escaping BeaconReporter.Submitter = Instana.reporter.submit(_:)) {
        self.state = state
        self.retryInterval = retryInterval
        self.submitter = submitter
        super.init()
    }
    
    private override init(timestamp: Instana.Types.Milliseconds, sessionId: String) {
        fatalError("Wrong initializer")
    }
}

private extension SessionProfileEvent {
    func handleCompletion(result: EventResult) -> Void {
        switch result {
        case .success:
            Instana.log.add("Session profile sent")
        case .failure(_):
            Instana.log.add("Failed to send session profile. Retrying in \(retryInterval) ms.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(retryInterval))) {
                self.submitter(self)
            }
            retryInterval *= 2
        }
    }
}

