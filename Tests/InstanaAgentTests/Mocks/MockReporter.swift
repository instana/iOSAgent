//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
@testable import InstanaAgent

class MockReporter: Reporter {
    var submitter: ((Beacon) -> Void)
    init(submitter: @escaping ((Beacon) -> Void)) {
        self.submitter = submitter
        super.init(InstanaSession.mock)
    }

    init() {
        self.submitter = {_ in}
        super.init(InstanaSession.mock)
    }

    override func submit(_ b: Beacon, _ completion: (() -> Void)? = nil) {
        submitter(b)
    }
}
