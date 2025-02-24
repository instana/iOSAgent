//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaApplicationStateHandlerTests: InstanaTestCase {

    func testLifecycle() {
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .inactive)

        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .active)

        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .inactive)
    }

    func testNSExtensionHost() {
        NotificationCenter.default.post(name: NSNotification.Name.NSExtensionHostWillResignActive, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .inactive)

        NotificationCenter.default.post(name: NSNotification.Name.NSExtensionHostDidBecomeActive, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .active)

        NotificationCenter.default.post(name: NSNotification.Name.NSExtensionHostDidEnterBackground, object: nil)
        AssertTrue(InstanaApplicationStateHandler.shared.state == .background)
    }
}
