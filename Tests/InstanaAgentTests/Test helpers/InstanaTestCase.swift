import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTestCase: XCTestCase {

    var httpCaptureConfig: HTTPCaptureConfig!
    var monitorTypes: Set<InstanaConfiguration.MonitorTypes>!
    var config: InstanaConfiguration!
    var key: String!
    var sessionID: UUID!
    var instana: Instana!

    override func setUp() {
        super.setUp()
        key = "KEY"
        sessionID = UUID()
        InstanaSystemUtils.isAppActive = true
        httpCaptureConfig = .automatic
        config = .default(key: key, reportingURL: .random, httpCaptureConfig: httpCaptureConfig)
        instana = Instana(configuration: config)
        Instana.current = instana
    }

    override func tearDown() {
        Instana.current = nil
        instana = nil
        InstanaSystemUtils.isAppActive = false
        super.tearDown()
    }
}
