//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import UIKit
@testable import InstanaSessionReplay

class MockWindowProvider: ActiveWindowProvider {
    let window: UIWindow?

    init(activeKeyWindow: UIWindow?) {
        window = activeKeyWindow
    }

    var activeKeyWindow: UIWindow? {
        return window
    }
}
