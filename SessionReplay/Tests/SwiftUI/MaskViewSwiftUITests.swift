//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
import SwiftUI
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class MaskViewSwiftUITests: XCTestCase {

    var window: UIWindow!

    override func setUp() {
        super.setUp()
        _ = Instana.setup(key: "TEST_KEY",
                          reportingURL: URL(string: "http://localhost")!,
                          options: nil)
        window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window = nil
        InstanaSessionReplay.current = nil
        Instana.current = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a sampled InstanaSessionReplay with the given mask strategy and sets it as current.
    @discardableResult
    private func setupSessionReplay(maskStrategy: MaskingStrategy = .mask_sensitive) throws -> InstanaSessionReplay {
        let config = InstanaSessionReplayConfig(maskStrategy: maskStrategy)
        config.isSampled = true
        let sr = try InstanaSessionReplay(config: config)
        InstanaSessionReplay.current = sr
        return sr
    }

    // MARK: - ShieldedUIView: didMoveToSuperview

    func test_shieldedUIView_addedToSuperview_callsMaskView() throws {
        // Given
        let sr = try setupSessionReplay()
        XCTAssertEqual(sr.maskedViews.count, 0)
        let shieldedView = ShieldedUIView()
        let parentView = UIView()

        // When
        parentView.addSubview(shieldedView)

        // Then
        XCTAssertEqual(sr.maskedViews.count, 1)
        XCTAssertTrue(sr.maskedViews.first?.value === shieldedView)
    }

    func test_shieldedUIView_removedFromSuperview_callsUnmaskView() throws {
        // Given
        let sr = try setupSessionReplay()
        let shieldedView = ShieldedUIView()
        let parentView = UIView()
        parentView.addSubview(shieldedView)
        XCTAssertEqual(sr.maskedViews.count, 1)

        // When
        shieldedView.removeFromSuperview()

        // Then
        XCTAssertEqual(sr.maskedViews.count, 0)
    }

    func test_shieldedUIView_reparented_remainsMasked() throws {
        // Given
        let sr = try setupSessionReplay()
        let shieldedView = ShieldedUIView()
        let parentA = UIView()
        let parentB = UIView()

        parentA.addSubview(shieldedView)
        XCTAssertEqual(sr.maskedViews.count, 1)

        // When – UIKit's addSubview to a new parent fires didMoveToSuperview once with the new
        // superview (parentB); it does NOT fire a separate didMoveToSuperview(nil) first, so
        // unmaskView is NOT called. maskView is called a second time, appending another WeakRef.
        parentB.addSubview(shieldedView)

        // Then – shieldedView appears twice in maskedViews (once per maskView call) and is
        // still reachable via the most-recently appended entry.
        XCTAssertEqual(sr.maskedViews.count, 2)
        XCTAssertTrue(sr.maskedViews.contains { $0.value === shieldedView })
    }

    func test_shieldedUIView_withMaskAllStrategy_doesNotAddToMaskedViews() throws {
        // Given
        let sr = try setupSessionReplay(maskStrategy: .mask_all)
        let shieldedView = ShieldedUIView()
        let parentView = UIView()

        // When
        parentView.addSubview(shieldedView)

        // Then – mask_all ignores explicit maskView calls
        XCTAssertEqual(sr.maskedViews.count, 0)
    }

    func test_shieldedUIView_withMaskNoneStrategy_doesNotAddToMaskedViews() throws {
        // Given
        let sr = try setupSessionReplay(maskStrategy: .mask_none)
        let shieldedView = ShieldedUIView()
        let parentView = UIView()

        // When
        parentView.addSubview(shieldedView)

        // Then – mask_none ignores explicit maskView calls
        XCTAssertEqual(sr.maskedViews.count, 0)
    }

    func test_shieldedUIView_withoutSessionReplay_doesNotCrash() {
        // Given – no active session replay instance
        XCTAssertNil(InstanaSessionReplay.current)
        let shieldedView = ShieldedUIView()
        let parentView = UIView()

        // When / Then – static calls on nil current must not crash
        parentView.addSubview(shieldedView)
        shieldedView.removeFromSuperview()
    }

    // MARK: - ShieldedUIViewRepresentable via UIHostingController

    func test_shieldedUIViewRepresentable_makeUIView_rendersShieldedUIView() {
        // Use a hosting controller so SwiftUI provides a real context and calls makeUIView.
        var capturedView: ShieldedUIView?
        let representable = ShieldedUIViewRepresentable(onCreate: { capturedView = $0 })
        let host = UIHostingController(rootView: representable)
        window.rootViewController = host
        host.view.layoutIfNeeded()

        // Wait one run-loop for SwiftUI to commit the view tree
        let exp = expectation(description: "SwiftUI renders")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertNotNil(capturedView, "onCreate should have been called with the ShieldedUIView")
    }

    func test_shieldedUIViewRepresentable_makeUIView_noOnCreate_doesNotCrash() {
        // Given – onCreate is nil
        let representable = ShieldedUIViewRepresentable(onCreate: nil)
        let host = UIHostingController(rootView: representable)
        window.rootViewController = host

        // When / Then – must not crash
        let exp = expectation(description: "SwiftUI renders without onCreate")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            host.view.layoutIfNeeded()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_shieldedUIViewRepresentable_updateUIView_isNoOp() throws {
        // Given – set up session replay so mask calls are tracked
        let sr = try setupSessionReplay()
        var capturedView: ShieldedUIView?
        let representable = ShieldedUIViewRepresentable(onCreate: { capturedView = $0 })
        let host = UIHostingController(rootView: representable)
        window.rootViewController = host
        host.view.layoutIfNeeded()

        let renderExp = expectation(description: "initial render")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { renderExp.fulfill() }
        wait(for: [renderExp], timeout: 1.0)

        let countAfterMake = sr.maskedViews.count

        // When – force a SwiftUI update pass; updateUIView must not alter maskedViews
        host.rootView = representable
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        let updateExp = expectation(description: "update pass")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { updateExp.fulfill() }
        wait(for: [updateExp], timeout: 1.0)

        // Then – mask count unchanged
        XCTAssertEqual(sr.maskedViews.count, countAfterMake)
        _ = capturedView // suppress unused warning
    }

    // MARK: - ShieldedUIViewRepresentable: maskView integration via hosting

    func test_shieldedUIViewRepresentable_addedToWindow_masksView() throws {
        // Given
        let sr = try setupSessionReplay()

        // When – host a ShieldedUIViewRepresentable in a real window so didMoveToSuperview fires
        let host = UIHostingController(rootView: ShieldedUIViewRepresentable())
        window.rootViewController = host
        host.view.layoutIfNeeded()

        let exp = expectation(description: "view added to hierarchy")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then – the ShieldedUIView inside the representable must have registered itself
        XCTAssertGreaterThanOrEqual(sr.maskedViews.count, 1)
    }

    // MARK: - View extensions: sensitive() / sensitiveView()

    func test_sensitive_appliesModifierWithoutCrash() throws {
        // Given
        try setupSessionReplay()

        // When – wrap a view with sensitive() and render it
        let sensitiveView = Text("secret").sensitive()
        let host = UIHostingController(rootView: sensitiveView)
        window.rootViewController = host
        host.view.layoutIfNeeded()

        let exp = expectation(description: "sensitive() rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then – rendering completes without crash; the masked view list is updated
        XCTAssertNotNil(host.view)
    }

    func test_sensitiveView_appliesModifierWithoutCrash() throws {
        // Given
        try setupSessionReplay()

        // When – wrap a view with sensitiveView() and render it
        let sensitiveView = Text("secret").sensitiveView()
        let host = UIHostingController(rootView: sensitiveView)
        window.rootViewController = host
        host.view.layoutIfNeeded()

        let exp = expectation(description: "sensitiveView() rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertNotNil(host.view)
    }

    func test_sensitive_and_sensitiveView_produceSameEffect() throws {
        // Both modifiers must result in the same number of masked view registrations.
        let sr = try setupSessionReplay()

        // Render sensitive()
        let hostA = UIHostingController(rootView: Text("A").sensitive())
        window.rootViewController = hostA
        hostA.view.layoutIfNeeded()
        let expA = expectation(description: "sensitive rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expA.fulfill() }
        wait(for: [expA], timeout: 1.0)
        let countA = sr.maskedViews.count

        // Reset
        window.rootViewController = nil
        InstanaSessionReplay.current = nil
        let sr2 = try setupSessionReplay()

        // Render sensitiveView()
        let hostB = UIHostingController(rootView: Text("B").sensitiveView())
        window.rootViewController = hostB
        hostB.view.layoutIfNeeded()
        let expB = expectation(description: "sensitiveView rendered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expB.fulfill() }
        wait(for: [expB], timeout: 1.0)
        let countB = sr2.maskedViews.count

        XCTAssertEqual(countA, countB, "sensitive() and sensitiveView() must register the same number of masked views")
    }
}
