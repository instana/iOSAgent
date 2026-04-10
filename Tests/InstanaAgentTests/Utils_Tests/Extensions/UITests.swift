import XCTest
@testable import InstanaAgent

final class UITests: InstanaTestCase {
    func test_instanaSetViewAutomatically_is_idempotent() {
        UIViewController.instanaSetViewAutomatically()

        let onceViewDidLoad = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidLoad))
        let onceViewWillAppear = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)))
        let onceViewDidAppear = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))

        UIViewController.instanaSetViewAutomatically()

        let twiceViewDidLoad = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidLoad))
        let twiceViewWillAppear = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)))
        let twiceViewDidAppear = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))

        XCTAssertNotNil(onceViewDidLoad)
        XCTAssertNotNil(onceViewWillAppear)
        XCTAssertNotNil(onceViewDidAppear)
        XCTAssertEqual(method_getImplementation(onceViewDidLoad!), method_getImplementation(twiceViewDidLoad!))
        XCTAssertEqual(method_getImplementation(onceViewWillAppear!), method_getImplementation(twiceViewWillAppear!))
        XCTAssertEqual(method_getImplementation(onceViewDidAppear!), method_getImplementation(twiceViewDidAppear!))
    }
}

