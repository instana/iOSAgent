//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTestCase: XCTestCase {

    private static let sid = UUID()
    private static let sharedInstana: Instana = {
        var config = InstanaConfiguration.mock(key: "KEY", reportingURL: .random, httpCaptureConfig: .automatic)
        config.gzipReport = false
        let session = InstanaSession.mock(configuration: config)

        let mockReporter = MockReporter()
        let mockMonitors = Monitors(session, reporter: mockReporter)

        let instana = Instana(session: session, monitors: mockMonitors)
        Instana.current = instana
        return instana
    }()

    var httpCaptureConfig: HTTPCaptureConfig!
    var monitorTypes: Set<InstanaConfiguration.MonitorTypes>!
    var config: InstanaConfiguration { instana.session.configuration }
    var key: String { config.key }
    var sessionID: UUID { InstanaTestCase.sid }
    var instana: Instana { InstanaTestCase.sharedInstana }
    var session: InstanaSession!

    override func setUp() {
        super.setUp()

        // Testing a sinlgeton is actually a nogo. But here we have to deal with it
        // Cache the instana instance to improve the performance of our tests. re-creating Instana for every tests is expensive
        if Instana.current == nil || InstanaTestCase.sharedInstana != Instana.current {
            Instana.current = InstanaTestCase.sharedInstana
        }
        session = instana.session
        cleanUp()
        InstanaApplicationStateHandler.shared.state = .active
    }

    override func tearDown() {
        cleanUp()
        super.tearDown()
    }

    func cleanUp() {
        InstanaApplicationStateHandler.shared.removeAllListener()
        Instana.current?.session.propertyHandler.properties = InstanaProperties()
        Instana.current?.monitors.reporter.queue.removeAll()
        IgnoreURLHandler.exactURLs.removeAll()
        IgnoreURLHandler.regex.removeAll()
        IgnoreURLHandler.urlSessions.removeAll()
        PreviousSession.cleanupPreviousSessionUserDefaults()
        UserDefaults.standard.removeObject(forKey: userSessionIDKey)
        UserDefaults.standard.removeObject(forKey: usi_startTimeKey)
    }
}
