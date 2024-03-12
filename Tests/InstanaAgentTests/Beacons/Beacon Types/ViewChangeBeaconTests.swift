import XCTest
@testable import InstanaAgent

class ViewChangeBeaconTests: InstanaTestCase {
    class TestUIViewController: UIViewController {
    }

    let testVC = TestUIViewController()
    let testClassName = String(describing: type(of: TestUIViewController.self))

    let testTimestamp: Instana.Types.Milliseconds = Date.distantPast.millisecondsSince1970
    let testViewName = "test view name 0"
    let testAcsbLabel = "test accessibilityLabel 1"
    let testNavItemTitle = "test navigationItemTitle 2"

    override func setUp() {
        super.setUp()
        typeAutoCaptureScreenNames = .none
        autoViewCaptureAllowedClasses = []
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

    func test_allowCapture_none() {
        // Given
        typeAutoCaptureScreenNames = .none
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: testAcsbLabel, navigationItemTitle: testNavItemTitle, className: testClassName)
        // Then
        XCTAssertFalse(allowed)
    }

    func test_allowCapture_all() {
        // Given
        typeAutoCaptureScreenNames = .allUIViewControllers
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: testAcsbLabel, navigationItemTitle: testNavItemTitle, className: "AnyClassName")
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_accessibilityLabel() {
        // Given
        typeAutoCaptureScreenNames = .interestedUIViewControllers
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: testAcsbLabel, navigationItemTitle: nil, className: "NotUsedClassName")
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_navigationItemTitle() {
        // Given
        typeAutoCaptureScreenNames = .interestedUIViewControllers
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: testNavItemTitle, className: "NotUsedClassName")
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_interestedUIViewControllers() {
        // Given
        typeAutoCaptureScreenNames = .interestedUIViewControllers
        autoViewCaptureAllowedClasses = [testClassName]
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: nil, className: testClassName)
        // Then
        XCTAssertTrue(allowed)
    }

    func test_allowCapture_interestedUIViewControllers_negative() {
        // Given
        typeAutoCaptureScreenNames = .interestedUIViewControllers
        // When
        let allowed = testVC.allowCapture(accessibilityLabel: nil, navigationItemTitle: nil, className: "NotUsedClassName")
        // Then
        XCTAssertFalse(allowed)
    }

    func test_instanaSetViewAutomatically() {
        // Given
        typeAutoCaptureScreenNames = .allUIViewControllers
        UIViewController.instanaSetViewAutomatically()

        // When
        let vcAfterSwizzle = TestUIViewController()
        _ = vcAfterSwizzle.view  // load the view hierarchy
        vcAfterSwizzle.viewDidAppear(false)
        Thread.sleep(forTimeInterval: 1)
    }
}
