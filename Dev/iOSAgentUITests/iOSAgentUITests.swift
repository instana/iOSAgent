//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest

class iOSAgentUITests: XCTestCase {

    var app: XCUIApplication!
    var webserver: Webserver!
    let port: UInt16 = 9999
    var instanaKey: String!

    override func setUp() {
        cleanCache()
        instanaKey = "\((0...100).randomElement()!)-Key"
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        webserver.stop()
        webserver = nil
    }

    func test_Launch_and_enter_url() {
        // Given
        launchServer()
        launchApp()

        // When
        load("https://api.mygigs.tapwork.de")

        // Then
        delay(3.0)
        webserver.verifyBeaconReceived(key: "t", value: "httpRequest")
        webserver.verifyBeaconReceived(key: "hu", value: "https://api.mygigs.tapwork.de")
        webserver.verifyBeaconReceived(key: "k", value: instanaKey)

        let types = webserver.values(for: "t")
        XCTAssertTrue(types.contains("sessionStart"))
        XCTAssertTrue(types.contains("viewChange"))
        XCTAssertTrue(types.contains("httpRequest"))
    }

    func test_start_new_session_after_launch() {
        // Given
        launchServer()
        launchApp()
        let firstSessionIDs = webserver.values(for: "sid")

        // When creating a new a new server app instance
        app.terminate()
        webserver.stop()
        launchApp(ignoreQueuePersistence: true)
        launchServer()
        delay(3.0)
        load("https://api.mygigs.tapwork.de")
        let newSessionids = webserver.values(for: "sid")

        // Then
        XCTAssertTrue(firstSessionIDs.count > 0)
        XCTAssertTrue(newSessionids.count > 0)
        XCTAssertNotEqual(firstSessionIDs.first, newSessionids.first)
    }

    func test_start_restore_queue_after_new_launch() {
        // Given: We don't have a running server at the first launch
        launchApp()

        // When
        load("https://api.mygigs.tapwork.de")

        // When creating a new a new server app instance
        app.terminate()
        launchServer()
        launchApp(ignoreQueuePersistence: false)
        load("https://www.google.com")

        // Then we expect both beacons (1st & 2nd app launch)
        webserver.verifyBeaconReceived(key: "hu", value: "https://api.mygigs.tapwork.de")
        webserver.verifyBeaconReceived(key: "hu", value: "https://www.google.com")
    }

    // MARK: Helper
    func launchServer(stubbedHTTPResponse: Webserver.HTTPStatusCode = .default) {
        webserver = Webserver(port: port)
        webserver.start()
        webserver.stub(httpStatusResponse: stubbedHTTPResponse)
        delay(5.0)
    }

    func launchApp(ignoreQueuePersistence: Bool = true) {
        app = XCUIApplication()
        app.launchArguments = ["-reportingURL", "http://127.0.0.1:\(port)",
                                "-key", instanaKey,
                                "-IgnoreZIPReporting", "true",
                                "-INSTANA_IGNORE_QUEUE_PERSISTENCE", ignoreQueuePersistence ? "true" : "false"]
        app.launch()
        delay(3.0)
    }

    func load(_ url: String) {
        let urlTextField = app.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText(url)
        app.buttons["     GO     "].tap()
        delay(4.0)
    }
}

func delay(_ duration: TimeInterval) {
    RunLoop.current.run(until: Date().addingTimeInterval(duration))
}

func verify(_ element: XCUIElement, file: StaticString = #file, line: UInt = #line) {
    if !element.waitForExistence(timeout: 5) {
        XCTFail("Could not find element \(element)", file: file, line: line)
    }
}

func cleanCache() {
    let fileManager = FileManager.default
    let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!
    let enumerator = fileManager.enumerator(at: cacheURL, includingPropertiesForKeys: nil)
    while let file = enumerator?.nextObject() as? String {
        try? fileManager.removeItem(at: cacheURL.appendingPathComponent(file))
    }
}
