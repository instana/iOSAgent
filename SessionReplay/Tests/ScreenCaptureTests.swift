//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
import UIKit
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class ScreenCaptureTests: SessionReplayTestCaseBase {

    var stagingManager: StagingManager!
    var screenCapture: ScreenCapture!
    var mockSessionReplay: InstanaSessionReplay!

    var sut: TestViewController!

    override func setUp() {
        super.setUp()

//        sut = TestViewController()
//        window.rootViewController = sut
//        _ = sut.view    // force load the view

        // Create mock session replay
        let config = InstanaSessionReplayConfig(framePerSecond: 1.0,
                                                maskStrategy: .mask_sensitive,
                                                maskingColor: .black)
        try? InstanaSessionReplay.setup(config: config, autoStart: false)
        mockSessionReplay = InstanaSessionReplay.current

        // Create screen capture instance
        screenCapture = ScreenCapture(config: config,
                                      stagingManager: mockSessionReplay.stagingManager,
                                      windowProvider: mockWindowProvider)
    }

    override func tearDown() {
        screenCapture?.stopCapture()
        screenCapture = nil
        mockSessionReplay = nil
        InstanaSessionReplay.current = nil
        Instana.current = nil

        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_createsScreenshotCache() {
        // Then
        XCTAssertNotNil(screenCapture.screenshotCache)
    }

    func test_init_setsDefaultValues() {
        // Then
        XCTAssertNil(screenCapture.timer)
        XCTAssertNil(screenCapture.lastHash)
    }

    // MARK: - useFastDrawing Tests

    func test_useFastDrawing_returnsFalse_whenConfigIsNil() {
        // Given
        mockSessionReplay.config.useFastScreenCapture = nil

        // When
        let result = screenCapture.useFastDrawing

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Timer Tests

    func test_startCapture_startsTimer_onMainThread() {
        // Given
        XCTAssertNil(screenCapture.timer)

        // When
        let expectation = self.expectation(description: "Timer started")
        screenCapture.startCapture()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(self.screenCapture.timer)
        XCTAssertTrue(self.screenCapture.timer?.isValid ?? false)
    }

    func test_startCapture_startsTimer_fromBackgroundThread() {
        // Given
        XCTAssertNil(screenCapture.timer)

        let backgroundExpectation = self.expectation(description: "Background notification received")
        let activeExpectation = self.expectation(description: "Active notification received")

        // Observe didBecomeActiveNotification to check timer
        let observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // Then - verify timer is started when app becomes active
            XCTAssertNotNil(self.screenCapture.timer, "Timer should be started")
            XCTAssertTrue(self.screenCapture.timer?.isValid ?? false, "Timer should be valid")
            activeExpectation.fulfill()
        }

        // When - post didEnterBackgroundNotification and start capture
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        DispatchQueue.global(qos: .background).async {
            self.screenCapture.startCapture()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                backgroundExpectation.fulfill()

                // Post didBecomeActiveNotification after capture is started
                NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            }
        }

        wait(for: [backgroundExpectation, activeExpectation], timeout: 2.0)

        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }

    func test_stopCapture_invalidatesTimer() {
        // Given
        let expectation = self.expectation(description: "Timer started then stopped")
        screenCapture.startCapture()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(self.screenCapture.timer)

        // When
        self.screenCapture.stopCapture()

        // Then
        XCTAssertNil(self.screenCapture.timer)
    }

    func test_stopCapture_whenTimerIsNil_doesNotCrash() {
        // Given
        XCTAssertNil(screenCapture.timer)

        // When/Then - should not crash
        screenCapture.stopCapture()
        XCTAssertNil(screenCapture.timer)
    }

    // MARK: - Screenshot Cache Tests

    // MARK: - Visibility Tests

//    func test_isVisible_returnsFalse_whenViewIsHidden() {
//        // Given
//        let view = UIView()
//        view.isHidden = true
//
//        // When
//        let result = screenCapture.value(forKey: "isVisible", with: view) as? Bool
//
//        // Then
//        XCTAssertFalse(result ?? true)
//    }
//
//    func test_isVisible_returnsFalse_whenAlphaIsZero() {
//        // Given
//        let view = UIView()
//        view.alpha = 0
//
//        // When
//        let result = screenCapture.value(forKey: "isVisible", with: view) as? Bool
//
//        // Then
//        XCTAssertFalse(result ?? true)
//    }

    func test_takeSnapshotForWindow_maskAll() {
        // Given
        screenCapture.config.maskStrategy = .mask_all

        sut = TestViewController()
        window.rootViewController = sut
        _ = sut.view    // force load the view

        // When
        screenCapture.takeSnapshotForWindow(window)

        // Then
        Thread.sleep(forTimeInterval: 0.1)
    }


    func test_takeSnapshotForWindow_maskMarked() {
        // Given
        screenCapture.config.maskStrategy = .mask_sensitive

        sut = TestViewController()
        window.rootViewController = sut
        _ = sut.view    // force load the view

        // force layout
        window.layoutIfNeeded()
        window.rootViewController?.view.layoutIfNeeded()

        // Give UIKit a moment to layout and commit the window/view
//        CATransaction.begin()
//        CATransaction.flush()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
//        CATransaction.commit()

        // When
        screenCapture.takeSnapshotForWindow(window)

        // Then
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskNone() {
        // Given
        screenCapture.config.maskStrategy = .mask_none

        sut = TestViewController()
        window.rootViewController = sut
        _ = sut.view    // force load the view

        // When
        screenCapture.takeSnapshotForWindow(window)

        // Then
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_useFastDrawing() {
        // Given
        mockSessionReplay.config.useFastScreenCapture = true

        // When

        screenCapture.takeSnapshotForWindow(window)

        // Then
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_useFastDrawing_returnsTrue_whenConfigIsTrue() {
        // A fresh ScreenCapture whose lazy var hasn't been read yet
        let config = InstanaSessionReplayConfig()
        config.useFastScreenCapture = true
        let sc = ScreenCapture(config: config,
                               stagingManager: mockSessionReplay.stagingManager,
                               windowProvider: mockWindowProvider)
        XCTAssertTrue(sc.useFastDrawing)
    }

    func test_useFastDrawing_returnsFalse_whenConfigIsFalse() {
        let config = InstanaSessionReplayConfig()
        config.useFastScreenCapture = false
        let sc = ScreenCapture(config: config,
                               stagingManager: mockSessionReplay.stagingManager,
                               windowProvider: mockWindowProvider)
        XCTAssertFalse(sc.useFastDrawing)
    }

    // MARK: - onLowMemory Tests

    func test_onLowMemory_clearsLastHash() {
        // Given – seed a hash value so we can confirm it's cleared
        screenCapture.lastHash = 12345
        screenCapture.screenshotCache.insert(12345, value: 0)

        // When
        screenCapture.onLowMemory()

        let exp = expectation(description: "imageQueue flush")
        screenCapture.imageQueue.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertNil(screenCapture.lastHash)
        XCTAssertEqual(screenCapture.screenshotCache.allKeys.count, 0)
    }

    func test_onLowMemory_onEmptyCache_doesNotCrash() {
        XCTAssertNil(screenCapture.lastHash)
        screenCapture.onLowMemory()

        let exp = expectation(description: "imageQueue flush")
        screenCapture.imageQueue.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertNil(screenCapture.lastHash)
    }

    // MARK: - startCapture with nil window Tests

    func test_startCapture_withNilWindow_registersForSceneActivation() {
        // Given – provider that returns nil window
        let nilWindowProvider = MockWindowProvider(activeKeyWindow: nil)
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001)
        let sc = ScreenCapture(config: config,
                               stagingManager: mockSessionReplay.stagingManager,
                               windowProvider: nilWindowProvider)

        // When
        let exp = expectation(description: "startCapture dispatched to main")
        DispatchQueue.main.async {
            sc.startCapture()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        // Timer should NOT be started yet (no window)
        XCTAssertNil(sc.timer)
    }

    func test_newSceneActivate_startsTimer() {
        // Given – provider that returns nil window so startCapture registers for the notification
        let nilWindowProvider = MockWindowProvider(activeKeyWindow: nil)
        let config = InstanaSessionReplayConfig(framePerSecond: 0.001)
        let sc = ScreenCapture(config: config,
                               stagingManager: mockSessionReplay.stagingManager,
                               windowProvider: nilWindowProvider)
        let startExp = expectation(description: "startCapture on main")
        DispatchQueue.main.async {
            sc.startCapture()
            startExp.fulfill()
        }
        wait(for: [startExp], timeout: 1.0)
        XCTAssertNil(sc.timer)

        // When – simulate UIScene.didActivateNotification
        // Switch the provider to one with a real window so startTimer can proceed
        sc.windowProvider = mockWindowProvider

        let timerExp = expectation(description: "timer started after scene activation")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                timerExp.fulfill()
            }
        }
        wait(for: [timerExp], timeout: 2.0)

        // Then
        XCTAssertNotNil(sc.timer)
        sc.stopCapture()
    }

    // MARK: - startTimer Idempotency

    func test_startCapture_calledTwice_doesNotDuplicateTimer() {
        // Given
        screenCapture.startCapture()
        let exp1 = expectation(description: "first startCapture")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp1.fulfill() }
        wait(for: [exp1], timeout: 1.0)
        let firstTimer = screenCapture.timer

        // When
        screenCapture.startCapture()
        let exp2 = expectation(description: "second startCapture")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp2.fulfill() }
        wait(for: [exp2], timeout: 1.0)

        // Then – same timer object, not a new one
        XCTAssertTrue(firstTimer === screenCapture.timer)
    }

    // MARK: - stopCapture from background thread

    func test_stopCapture_fromBackgroundThread_nilsTimer() {
        // Given – timer running
        screenCapture.startCapture()
        let startExp = expectation(description: "timer started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)
        XCTAssertNotNil(screenCapture.timer)

        // When – stop from background thread
        let stopExp = expectation(description: "timer stopped")
        DispatchQueue.global(qos: .background).async {
            self.screenCapture.stopCapture()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                stopExp.fulfill()
            }
        }
        wait(for: [stopExp], timeout: 2.0)

        // Then
        XCTAssertNil(screenCapture.timer)
    }

    // MARK: - takeSnapshot guard Tests

    func test_takeSnapshot_withNilSessionReplay_doesNotCrash() {
        // Given – sessionReplay is nil (weak reference)
        screenCapture.sessionReplay = nil

        // When / Then – should not crash
        screenCapture.takeSnapshot()
    }

    func test_takeSnapshot_withNilWindow_doesNotCrash() {
        // Given – provider with nil window; sessionReplay set
        let nilWindowProvider = MockWindowProvider(activeKeyWindow: nil)
        let config = InstanaSessionReplayConfig(framePerSecond: 1.0)
        let sc = ScreenCapture(config: config,
                               stagingManager: mockSessionReplay.stagingManager,
                               windowProvider: nilWindowProvider)
        sc.sessionReplay = mockSessionReplay

        // When / Then – should not crash
        sc.takeSnapshot()
    }

    func test_takeSnapshot_whenUserRecentlyActive_capturesSnapshot() {
        // Given – lastTouchTime is now (user is "active")
        screenCapture.sessionReplay = mockSessionReplay
        mockSessionReplay.userEvent.lastTouchTime = Date().millisecondsSince1970

        // When / Then – should not crash; snapshot pipeline runs
        screenCapture.takeSnapshot()

        let exp = expectation(description: "imageQueue flush")
        screenCapture.imageQueue.async { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)
    }

    func test_takeSnapshot_whenUserLongIdle_skipsCapture() {
        // Given – lastTouchTime is far in the past (more than interval + 3s idle leeway)
        screenCapture.sessionReplay = mockSessionReplay
        // Set last touch to 1 minute ago
        mockSessionReplay.userEvent.lastTouchTime = Date().millisecondsSince1970 - 60_000

        // When
        let previousHash = screenCapture.lastHash
        screenCapture.takeSnapshot()

        let exp = expectation(description: "imageQueue flush")
        screenCapture.imageQueue.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Then – lastHash unchanged (no snapshot was taken)
        XCTAssertEqual(screenCapture.lastHash, previousHash)
    }

    // MARK: - calculatePHash Tests

    func test_calculatePHash_returnsNonNilForValidImage() {
        // Given – a simple solid-color UIImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }

        // When
        let hash = screenCapture.calculatePHash(image)

        // Then
        XCTAssertNotNil(hash)
    }

    func test_calculatePHash_returnsDifferentHashForDifferentImages() {
        // pHash converts to grayscale before hashing, so images that differ only in
        // hue (e.g. red vs blue) can produce the same luminance and the same hash.
        // Use structurally distinct images: solid white vs a black-and-white checker.
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        // Image A – solid white
        let imageA = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        // Image B – black-and-white checkerboard (strong structural difference after grayscale)
        let imageB = renderer.image { ctx in
            let tileSize: CGFloat = 10
            for row in 0..<10 {
                for col in 0..<10 {
                    let color: UIColor = (row + col) % 2 == 0 ? .white : .black
                    color.setFill()
                    ctx.fill(CGRect(x: CGFloat(col) * tileSize,
                                   y: CGFloat(row) * tileSize,
                                   width: tileSize, height: tileSize))
                }
            }
        }

        // When
        let hashA = screenCapture.calculatePHash(imageA)
        let hashB = screenCapture.calculatePHash(imageB)

        // Then
        XCTAssertNotNil(hashA)
        XCTAssertNotNil(hashB)
        XCTAssertNotEqual(hashA, hashB)
    }

    func test_calculatePHash_returnsSameHashForIdenticalImages() {
        // Given
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }

        // When
        let hash1 = screenCapture.calculatePHash(image)
        let hash2 = screenCapture.calculatePHash(image)

        // Then
        XCTAssertEqual(hash1, hash2)
    }

    // MARK: - mask_input_fields strategy Tests

    func test_takeSnapshotForWindow_maskInputFields_withTextField() {
        // Given
        screenCapture.config.maskStrategy = .mask_input_fields

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let tf = UITextField(frame: CGRect(x: 10, y: 50, width: 200, height: 40))
        tf.text = "secret"
        vc.view.addSubview(tf)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskInputFields_withEmptyTextField() {
        // Given
        screenCapture.config.maskStrategy = .mask_input_fields

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let tf = UITextField(frame: CGRect(x: 10, y: 50, width: 200, height: 40))
        tf.text = ""   // empty – containVisibleInfo returns false
        vc.view.addSubview(tf)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskInputFields_withLabel() {
        // Given
        screenCapture.config.maskStrategy = .mask_input_fields

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 30))
        lbl.text = "Visible label"
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskInputFields_withEmptyLabel() {
        // Given
        screenCapture.config.maskStrategy = .mask_input_fields

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 30))
        lbl.text = nil   // empty – containVisibleInfo returns false
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    // MARK: - containVisibleInfo via mask_all strategy Tests

    func test_takeSnapshotForWindow_maskAll_textViewWithContent() {
        // Given
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let tv = UITextView(frame: CGRect(x: 10, y: 50, width: 200, height: 80))
        tv.text = "Hello world"
        vc.view.addSubview(tv)
        window.layoutIfNeeded()

        // When / Then – no crash; UITextView with content should be masked
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskAll_textViewEmpty() {
        // Given
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let tv = UITextView(frame: CGRect(x: 10, y: 50, width: 200, height: 80))
        tv.text = ""  // empty – containVisibleInfo returns false
        vc.view.addSubview(tv)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskAll_imageViewWithImage() {
        // Given
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        let img = renderer.image { ctx in UIColor.red.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 50)) }

        let iv = UIImageView(frame: CGRect(x: 10, y: 50, width: 50, height: 50))
        iv.image = img
        vc.view.addSubview(iv)
        window.layoutIfNeeded()

        // When / Then – UIImageView with image should be masked
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskAll_imageViewWithoutImage() {
        // Given
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let iv = UIImageView(frame: CGRect(x: 10, y: 50, width: 50, height: 50))
        iv.image = nil  // no image – containVisibleInfo returns false
        vc.view.addSubview(iv)
        window.layoutIfNeeded()

        // When / Then
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_maskAll_genericView() {
        // Given – a plain UIView (not any of the special types); containVisibleInfo returns true
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        // Plain UIView – shouldMaskView returns false for mask_all (it only masks specific types)
        let plainView = UIView(frame: CGRect(x: 10, y: 50, width: 100, height: 100))
        plainView.backgroundColor = .systemBlue
        vc.view.addSubview(plainView)
        window.layoutIfNeeded()

        // When / Then – no crash
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    // MARK: - clipsToBounds clipping Tests

    func test_takeSnapshotForWindow_clipsTooBoundsContainer() {
        // Given – a scroll-view style container that clips subviews
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let container = UIScrollView(frame: CGRect(x: 10, y: 50, width: 200, height: 80))
        container.clipsToBounds = true
        vc.view.addSubview(container)

        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        lbl.text = "Clipped label"
        container.addSubview(lbl)

        window.layoutIfNeeded()

        // When / Then – no crash; clipping rect logic is exercised
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    // MARK: - mask_sensitive with empty masked view list Tests

    func test_takeSnapshotForWindow_maskSensitive_emptyMaskedList_exitsEarly() {
        // Given – mask_sensitive but no views registered → maskedViewsProgress == []
        // The traverse inner function bails immediately when the list is empty.
        screenCapture.config.maskStrategy = .mask_sensitive
        // InstanaSessionReplay.current has no masked views (empty list)

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 30))
        lbl.text = "Label"
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash; early-exit path exercised
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    // MARK: - Hidden / zero-size view visibility Tests

    func test_takeSnapshotForWindow_hiddenView_isSkipped() {
        // Exercises the isVisible() guard for isHidden
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 30))
        lbl.text = "Hidden"
        lbl.isHidden = true
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash; hidden view is skipped in traverse
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_zeroAlphaView_isSkipped() {
        // Exercises the isVisible() guard for alpha == 0
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 30))
        lbl.text = "Transparent"
        lbl.alpha = 0
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash; alpha==0 view is skipped
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func test_takeSnapshotForWindow_zeroSizeView_isSkipped() {
        // Exercises the isVisible() guard for zero bounds
        screenCapture.config.maskStrategy = .mask_all

        let vc = UIViewController()
        window.rootViewController = vc
        _ = vc.view

        let lbl = UILabel(frame: .zero)
        lbl.text = "Zero size"
        vc.view.addSubview(lbl)
        window.layoutIfNeeded()

        // When / Then – no crash; zero-size view is skipped
        screenCapture.takeSnapshotForWindow(window)
        Thread.sleep(forTimeInterval: 0.1)
    }

}

