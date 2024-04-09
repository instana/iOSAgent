import XCTest
@testable import InstanaAgent

class ViewChangeBeaconTests: InstanaTestCase {
    class TestUIViewController: UIViewController {
    }

    let testVC = TestUIViewController()
    let testClassType = type(of: TestUIViewController.self)
    let testClassName = String(describing: type(of: TestUIViewController.self))

    let testTimestamp: Instana.Types.Milliseconds = Date.distantPast.millisecondsSince1970
    let testViewName = "test view name 0"
    let testAcsbLabel = "test accessibilityLabel 1"
    let testNavItemTitle = "test navigationItemTitle 2"

    override func setUp() {
        super.setUp()
    }

    func test_init_accessibilityLabel() {
        // When
        let vcBeacon = ViewChange(timestamp: testTimestamp, viewName: testViewName,
                                  accessibilityLabel: testAcsbLabel, navigationItemTitle: testNavItemTitle, className: testClassName)
        // Then
        XCTAssertEqual(vcBeacon.viewName!, "\(testAcsbLabel) @\(testClassName)")
    }

    func test_init_navigationItemTitle() {
        // When
        let vcBeacon = ViewChange(timestamp: testTimestamp, viewName: testViewName,
                                  accessibilityLabel: nil, navigationItemTitle: testNavItemTitle, className: testClassName)
        // Then
        XCTAssertEqual(vcBeacon.viewName!, "\(testNavItemTitle) @\(testClassName)")
    }

    func test_allowCapture_false() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = false
        Instana.current?.session.debugAllScreenNames = false
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: nil,
                                          class: TestUIViewController.self, isSwiftUI: false)
        // Then
        XCTAssertFalse(allowed)
    }

    func test_allowCapture_all() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = true
        Instana.current?.session.debugAllScreenNames = false
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: testAcsbLabel,
                                          navigationItemTitle: testNavItemTitle,
                                          class: TestUIViewController.self,
                                          isSwiftUI: false)
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_accessibilityLabel() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = true
        Instana.current?.session.debugAllScreenNames = false
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: testAcsbLabel, navigationItemTitle: nil,
                                          class: TestUIViewController.self, isSwiftUI: false)
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_navigationItemTitle() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = true
        Instana.current?.session.debugAllScreenNames = false
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: testNavItemTitle,
                                          class: TestUIViewController.self, isSwiftUI: false)
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_testClassUIViewControllers_debugAll() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = true
        Instana.current?.session.debugAllScreenNames = true
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: nil,
                                          class: TestUIViewController.self, isSwiftUI: false)
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_testClassUIViewControllers_swiftUI() {
        // Given
        Instana.current?.session.autoCaptureScreenNames = true
        Instana.current?.session.debugAllScreenNames = false
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: nil,
                                          class: TestUIViewController.self, /* not used */
                                          isSwiftUI: true)
        // Then
        XCTAssertFalse(allowed)
    }

    func test_instanaSetViewAutomatically() {
        // Given
        UIViewController.instanaSetViewAutomatically()

        // When
        let vcAfterSwizzle = TestUIViewController()
        _ = vcAfterSwizzle.view  // load the view hierarchy
        vcAfterSwizzle.viewDidAppear(false)
        Thread.sleep(forTimeInterval: 1)
    }
}
