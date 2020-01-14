import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTestCase: XCTestCase {

    private static let sid = UUID()
    private static let sharedInstana: Instana = {
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: .random, httpCaptureConfig: .automatic)
        let instana = Instana(configuration: config)
        Instana.current = instana
        return instana
    }()

    var httpCaptureConfig: HTTPCaptureConfig!
    var monitorTypes: Set<InstanaConfiguration.MonitorTypes>!
    var config: InstanaConfiguration { instana.environment.configuration }
    var key: String { config.key }
    var sessionID: UUID { InstanaTestCase.sid }
    var instana: Instana { InstanaTestCase.sharedInstana }

    override func setUp() {
        super.setUp()

        InstanaSystemUtils.isAppActive = true
        // Testing a sinlgeton is actually a nogo. But here we have to deal with it
        // Cache the instana instance to improve the performance of our tests. re-creating Instana for every tests is expensive
        if Instana.current == nil || InstanaTestCase.sharedInstana != Instana.current {
            Instana.current = InstanaTestCase.sharedInstana
        }
    }

    override func tearDown() {
        InstanaSystemUtils.isAppActive = false
        // Do some clean up
        Instana.current?.environment.propertyHandler.properties = InstanaProperties()
        super.tearDown()
    }
}
