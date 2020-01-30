//
//  iOSAgentExampleUITests.swift
//  iOSAgentExampleUITests
//
//  Created by Christian Menschel on 28.01.20.
//  Copyright © 2020 Instana Inc. All rights reserved.
//
import Foundation
import XCTest
@testable import iOSAgentExample

class iOSAgentExampleUITests: XCTestCase {

    var app: XCUIApplication!
    var webserver: Webserver!
    let port: UInt16 = 9999

    override func setUp() {
        cleanCache()
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
        app.tabBars.buttons["JSON"].tap()

        // When
        load("https://api.mygigs.tapwork.de")

        // Then
        verify(app.textViews.staticTexts["{\"message\":\"api.mygigs.tapwork.de\"}"])
        delay(2.0)
        webserver.verifyBeaconReceived(key: "t", value: "httpRequest")
        webserver.verifyBeaconReceived(key: "hu", value: "https://api.mygigs.tapwork.de")
    }

    func test_flush_after_error() {
        // Given
        launchServer(stubbedHTTPResponse: 404)
        launchApp()
        app.tabBars.buttons["JSON"].tap()

        // When (Server not found)
        load("https://api.mygigs.tapwork.de/search/Hergenrath?page=1&entity=venue")

        // Then (Beacon should not be transmitted)
        webserver.verifyBeaconNotReceived(key: "hp", value: "/search/Hergenrath")

        // When
        webserver.stub(httpStatusResponse: 200)
        delay(3.0)
        app.tabBars.buttons["Web"].tap()

        // Then
        verify(app.webViews.firstMatch)
        delay(3.0)
        webserver.verifyBeaconReceived(key: "t", value: "httpRequest")
        webserver.verifyBeaconReceived(key: "hp", value: "/search/Hergenrath")
        webserver.verifyBeaconReceived(key: "hu", value: "https://www.instana.com")
    }


    // MARK: Helper
    func launchServer(stubbedHTTPResponse: Webserver.HTTPStatusCode = .default) {
        webserver = Webserver(port: port)
        webserver.start()
        webserver.stub(httpStatusResponse: stubbedHTTPResponse)
    }

    func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["-reportingURL", "http://127.0.0.1:\(port)", "-key", "empty", "-IgnoreZIPReporting", "true"]
        app.launch()
    }

    func load(_ url: String) {
        let urlTextField = app.textFields["URL"]
        urlTextField.tap()
        urlTextField.typeText(url)
        app.buttons["     GO     "].tap()
        delay(2.0)
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
