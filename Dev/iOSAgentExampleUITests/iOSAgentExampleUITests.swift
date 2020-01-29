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
        webserver = Webserver(port: 9999)
        webserver.start()
        app = XCUIApplication()
        app.launchArguments = ["-reportingURL", "http://127.0.0.1:9999", "-key", "empty", "-IgnoreZIPReporting", "true"]
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

        (0...1).forEach {_ in
            app.buttons["     GO     "].tap()

            // Then
            let expected = app.textViews.staticTexts["{\"message\":\"api.mygigs.tapwork.de\"}"]
            verify(expected)
            verify(webserver, key: "hu", value: "https://api.mygigs.tapwork.de")
        }
    }
}

func verify(_ webserver: Webserver, key: String, value: String, file: StaticString = #file, line: UInt = #line) {
    if !webserver.verify(key: key, value: value) {
        XCTFail("Did not find transmitted beacon containing key: \(key) and value: \(value)", file: file, line: line)
    }
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
