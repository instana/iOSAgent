//
//  iOSAgentExampleUITests.swift
//  iOSAgentExampleUITests
//
//  Created by Christian Menschel on 28.01.20.
//  Copyright © 2020 Instana Inc. All rights reserved.
//

import XCTest
@testable import iOSAgentExample

class iOSAgentExampleUITests: XCTestCase {

    var app: XCUIApplication!
    var webserver: Webserver!

    override func setUp() {
        cleanCache()
        continueAfterFailure = false
        let port: UInt16 = 9999
        webserver = Webserver(port: port)
        webserver.start()
        app = XCUIApplication()
        app.launchArguments = ["-reportingURL", "http://127.0.0.1:\(port)", "-key", "empty", "-IgnoreZIPReporting", "true"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        webserver.stop()
        webserver = nil
    }

    func test_Launch_and_enter_url() {
        // When
        app.tabBars.buttons["JSON"].tap()
        let urlTextField = app.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText("https://api.mygigs.tapwork.de")
        app.buttons["     GO     "].tap()

        // Then
        verify(app.textViews.staticTexts["{\"message\":\"api.mygigs.tapwork.de\"}"])
        delay(2.0)
        webserver.verifyBeaconReceived(key: "t", value: "httpRequest")
        webserver.verifyBeaconReceived(key: "hu", value: "https://api.mygigs.tapwork.de")
    }

    func test_flush_after_error() {
        // When
        webserver.stub(httpStatusResponse: 404)
        app.tabBars.buttons["JSON"].tap()
        let urlTextField = app.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText("https://api.mygigs.tapwork.de")
        app.buttons["     GO     "].tap()

        // Then
        webserver.verifyBeaconNotReceived(key: "t", value: "httpRequest")

        // When
        webserver.stub(httpStatusResponse: 200)

        // Then
        app.buttons["     GO     "].tap()
        verify(app.textViews.staticTexts["{\"message\":\"api.mygigs.tapwork.de\"}"])
        delay(2.0)
        webserver.verifyBeaconReceived(key: "t", value: "httpRequest")
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
