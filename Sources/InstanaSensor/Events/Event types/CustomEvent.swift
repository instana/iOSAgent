//  Created by Nikola Lajic on 1/23/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

/// Use this class when submitting user events to the Instana backend.
@objc public class CustomEvent: Event {
    public let name: String
    public let duration: Instana.Types.Milliseconds

    @objc public init(name: String, duration: Instana.Types.Milliseconds = Date().millisecondsSince1970) {
        self.name = name
        self.duration = duration
        super.init()
    }
}
