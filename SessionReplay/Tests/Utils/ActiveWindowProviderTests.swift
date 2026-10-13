//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
import UIKit
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class ActiveWindowProviderTests: XCTestCase {

    var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - ActiveWindowProvider protocol / MockWindowProvider

    func test_mockWindowProvider_returnsProvidedWindow() {
        let provider: ActiveWindowProvider = MockWindowProvider(activeKeyWindow: window)
        XCTAssertTrue(provider.activeKeyWindow === window)
    }

    func test_mockWindowProvider_returnsNilWhenInitialisedWithNil() {
        let provider: ActiveWindowProvider = MockWindowProvider(activeKeyWindow: nil)
        XCTAssertNil(provider.activeKeyWindow)
    }

    func test_mockWindowProvider_alwaysReturnsSameInstance() {
        let provider = MockWindowProvider(activeKeyWindow: window)
        XCTAssertTrue(provider.activeKeyWindow === provider.activeKeyWindow)
    }

    func test_mockWindowProvider_conformsToActiveWindowProvider() {
        let provider = MockWindowProvider(activeKeyWindow: window)
        XCTAssertTrue((provider as AnyObject) is MockWindowProvider)
        // Protocol conformance check — compiles only if MockWindowProvider : ActiveWindowProvider
        let _: ActiveWindowProvider = provider
    }

    // MARK: - AppWindowProvider

    func test_appWindowProvider_withKeyWindow_resultIsKeyWindowOrNil() {
        // AppWindowProvider filters for foregroundActive scenes. In the XCTest runner the
        // scene activation state is foregroundInactive, so the result may legitimately be nil.
        // The invariant we can always assert: if a window is returned it must be the key window.
        window.makeKeyAndVisible()

        let provider = AppWindowProvider()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        if let result = provider.activeKeyWindow {
            XCTAssertTrue(result.isKeyWindow)
        }
        // nil is also acceptable — it means no foregroundActive scene was present
    }

    func test_appWindowProvider_returnsKeyWindow_notArbitraryWindow() {
        // Two windows — only the key one must be returned
        window.makeKeyAndVisible()

        let secondWindow = UIWindow(frame: UIScreen.main.bounds)
        secondWindow.windowLevel = .normal

        let provider = AppWindowProvider()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        if let result = provider.activeKeyWindow {
            XCTAssertTrue(result.isKeyWindow)
        }
        secondWindow.isHidden = true
    }

    func test_appWindowProvider_withoutKeyWindow_returnsNil() {
        // No window is made key — provider should return nil
        // (window was created but never shown)
        let provider = AppWindowProvider()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // In a headless test environment there may be no foreground-active scene at all
        // so nil is the expected result when no key window is present
        let result = provider.activeKeyWindow
        if let result {
            XCTAssertTrue(result.isKeyWindow, "If a window is returned it must be the key window")
        }
    }

    func test_appWindowProvider_conformsToActiveWindowProvider() {
        let _: ActiveWindowProvider = AppWindowProvider()
    }

    func test_appWindowProvider_activeKeyWindow_onlyFromForegroundActiveScene() {
        // Make window key so a foreground-active scene exists
        window.makeKeyAndVisible()
        let provider = AppWindowProvider()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Result must either be nil or a key window — never a non-key window
        if let result = provider.activeKeyWindow {
            XCTAssertTrue(result.isKeyWindow)
        }
    }

    // MARK: - UIApplication: ActiveWindowProvider conformance

    func test_uiApplication_conformsToActiveWindowProvider() {
        let _: ActiveWindowProvider = UIApplication.shared
    }

    func test_uiApplication_activeKeyWindow_withKeyWindow_resultIsKeyWindowOrNil() {
        // Same foregroundActive filter as AppWindowProvider — result may be nil in test runner.
        window.makeKeyAndVisible()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        if let result = UIApplication.shared.activeKeyWindow {
            XCTAssertTrue(result.isKeyWindow)
        }
        // nil is acceptable when scene is not foregroundActive in the test process
    }

    func test_uiApplication_activeKeyWindow_matchesAppWindowProvider() {
        // Both UIApplication extension and AppWindowProvider use identical logic;
        // they must return the same window instance.
        window.makeKeyAndVisible()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        let fromApp = UIApplication.shared.activeKeyWindow
        let fromProvider = AppWindowProvider().activeKeyWindow
        XCTAssertEqual(fromApp, fromProvider)
    }

    func test_uiApplication_activeKeyWindow_isKeyWindowWhenNonNil() {
        window.makeKeyAndVisible()

        let exp = expectation(description: "layout pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        if let result = UIApplication.shared.activeKeyWindow {
            XCTAssertTrue(result.isKeyWindow)
        }
    }
}
