//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

class SessionReplayTestCaseBase: XCTestCase {
    var window: UIWindow!
    var mockWindowProvider: ActiveWindowProvider!

    override func setUp() {
        super.setUp()

        UserDefaults.standard.removeObject(forKey: configSessionReplayStateKey)
        UserDefaults.standard.removeObject(forKey: configServerSideTimeStampKey)
        UserDefaults.standard.removeObject(forKey: FrequentRestart.keyRestartTimestamps)

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.makeKeyAndVisible()
        mockWindowProvider = MockWindowProvider(activeKeyWindow: window)

        // Setup Instana
        _ = Instana.setup(key: "TEST_KEY",
                          reportingURL: URL(string: "http://localhost")!,
                          options: nil)
    }

    override func tearDown() {
        InstanaSessionReplay.pauseRecording()
        InstanaSessionReplay.current = nil
        Instana.current = nil

        UserDefaults.standard.removeObject(forKey: configSessionReplayStateKey)
        UserDefaults.standard.removeObject(forKey: configServerSideTimeStampKey)
        UserDefaults.standard.removeObject(forKey: FrequentRestart.keyRestartTimestamps)

        mockWindowProvider = nil
        window = nil
        super.tearDown()
    }
}
