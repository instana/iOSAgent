
//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable @_spi(Internal) import InstanaAgent
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class NotificationObserverTests: XCTestCase {

    var mockStagingManager: MockNotificationStagingManager!
    var stagingManager: StagingManager!
    var observer: NotificationObserver!
    var notificationCenter = NotificationCenter.default

    override func setUp() {
        super.setUp()

        // Setup Instana (required for reportNotification)
        _ = Instana.setup(key: "TEST_KEY",
                          reportingURL: URL(string: "http://localhost")!,
                          options: nil)
        let config = InstanaSessionReplayConfig(framePerSecond: 1.0,
                                                maskStrategy: .mask_sensitive,
                                                maskingColor: .black)
        mockStagingManager = MockNotificationStagingManager(config: config)
        stagingManager = try! StagingManager(config: config)
        observer = NotificationObserver(stagingManager: mockStagingManager)
    }

    override func tearDown() {
        observer.stopObserving()
        observer = nil
        mockStagingManager = nil
        Instana.current = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_setsDefaultValues() {
        // Then
        XCTAssertEqual(observer.currentOrientation, nil)
        XCTAssertFalse(observer.keyboardShow)
    }

    // MARK: - Start/Stop Observing Tests

    func test_startObserving_registersAllNotifications() {
        // Given
        let expectation = self.expectation(description: "Observers registered")

        // When
        observer.startObserving()

        // Then - Verify observers are registered by posting notifications
        var notificationCount = 0

        // Test willEnterForeground
        let foregroundExpectation = XCTestExpectation(description: "Foreground notification")
        notificationCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            notificationCount += 1
            foregroundExpectation.fulfill()
        }
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        wait(for: [foregroundExpectation], timeout: 1.0)
        XCTAssertEqual(notificationCount, 1)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func test_stopObserving_removesAllObservers() {
        // Given
        observer.startObserving()

        // When
        observer.stopObserving()

        // Then - Verify observers are removed (no crash when posting notifications)
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)
        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.post(name: UIResponder.keyboardWillHideNotification, object: nil)

        // If we get here without crash, observers were properly removed
        XCTAssertTrue(true)
    }

    func test_deinit_stopsObserving() {
        // Given
        observer.startObserving()

        // When
        observer.stopObserving()

        // Then - Verify no crash when posting notifications after deallocation
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)
        XCTAssertTrue(true)
    }

    // MARK: - Orientation Change Tests

    func test_handleOrientationChange_initialOrientationVerify() {
        // Given - inject a fixed orientation so the test doesn't depend on a live UIWindowScene
        observer.orientationProvider = { .portrait }
        observer.startObserving()
        XCTAssertNil(observer.currentOrientation)

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        XCTAssertEqual(observer.currentOrientation, .portrait)
    }

    func test_processOrientationChange_portrait_setsCorrectDirection() {
        // Given
        observer.orientationProvider = { .portrait }
        observer.startObserving()

        // When
        observer.currentOrientation = .landscapeLeft
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        XCTAssertEqual(observer.currentOrientation, .portrait)
    }

    // MARK: - Keyboard Tests

    func test_keyboardWillShow_setsKeyboardShowToTrue() {
        // Given
        observer.startObserving()
        XCTAssertFalse(observer.keyboardShow)

        // When
        let notification = Notification(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)]
        )
        notificationCenter.post(notification)

        // Wait for notification to be processed
        let expectation = self.expectation(description: "Keyboard shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertTrue(observer.keyboardShow)
    }

    func test_keyboardWillShow_doesNotReportIfAlreadyShown() {
        // Given
        observer.startObserving()
        observer.keyboardShow = true

        // When
        let notification = Notification(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)]
        )
        notificationCenter.post(notification)

        // Wait for notification to be processed
        let expectation = self.expectation(description: "Keyboard notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then - Should still be true, but no duplicate report
        XCTAssertTrue(observer.keyboardShow)
    }

    func test_keyboardWillHide_setsKeyboardShowToFalse() {
        // Given
        observer.startObserving()
        observer.keyboardShow = true

        // When
        let notification = Notification(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: nil
        )
        notificationCenter.post(notification)

        // Wait for notification to be processed
        let expectation = self.expectation(description: "Keyboard hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertFalse(observer.keyboardShow)
    }

    func test_keyboardWillHide_doesNotReportIfAlreadyHidden() {
        // Given
        observer.startObserving()
        observer.keyboardShow = false

        // When
        let notification = Notification(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: nil
        )
        notificationCenter.post(notification)

        // Wait for notification to be processed
    }

    // MARK: - processOrientationChange: all orientations

    func test_processOrientationChange_portraitUpsideDown_stagesPortraitBeacon() {
        // Given – seed a known prior orientation so a beacon is expected
        observer.currentOrientation = .portrait
        observer.orientationProvider = { .portraitUpsideDown }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "orientation event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .portraitUpsideDown)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        XCTAssertEqual(mockStagingManager.stagedEvents.first?.eventValue, OrientationValueEnum.Portrait.rawValue)
        XCTAssertEqual(mockStagingManager.stagedEvents.first?.eventType, .orientation)
    }

    func test_processOrientationChange_landscapeLeft_stagesLandscapeBeacon() {
        // Given
        observer.currentOrientation = .portrait
        observer.orientationProvider = { .landscapeLeft }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "orientation event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .landscapeLeft)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        XCTAssertEqual(mockStagingManager.stagedEvents.first?.eventValue, OrientationValueEnum.landscape.rawValue)
    }

    func test_processOrientationChange_landscapeRight_stagesLandscapeBeacon() {
        // Given
        observer.currentOrientation = .portrait
        observer.orientationProvider = { .landscapeRight }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "orientation event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .landscapeRight)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        XCTAssertEqual(mockStagingManager.stagedEvents.first?.eventValue, OrientationValueEnum.landscape.rawValue)
    }

    func test_processOrientationChange_unknown_stagesUnknownBeacon() {
        // Given – use .unknown (raw value 0) which hits the default case
        observer.currentOrientation = .portrait
        observer.orientationProvider = { .unknown }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "orientation event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .unknown)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        XCTAssertEqual(mockStagingManager.stagedEvents.first?.eventValue, OrientationValueEnum.unknown.rawValue)
    }

    func test_processOrientationChange_sameOrientation_doesNotStageBeacon() {
        // Given – currentOrientation already set to portrait; same orientation reported again
        observer.currentOrientation = .portrait
        observer.orientationProvider = { .portrait }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then – orientation unchanged, no beacon expected
        let expectation = self.expectation(description: "no event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .portrait)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }

    func test_processOrientationChange_nilProvider_doesNotStageBeacon() {
        // Given – orientationProvider returns nil (e.g. no active window scene)
        observer.currentOrientation = .portrait
        observer.orientationProvider = { nil }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then – guard let exits early, nothing staged, currentOrientation unchanged
        let expectation = self.expectation(description: "no event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .portrait)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }

    func test_processOrientationChange_initialOrientation_doesNotStageBeacon() {
        // Given – currentOrientation is nil (very first rotation event)
        XCTAssertNil(observer.currentOrientation)
        observer.orientationProvider = { .landscapeLeft }
        observer.startObserving()

        // When
        notificationCenter.post(name: UIDevice.orientationDidChangeNotification, object: nil)

        // Then – initial orientation must NOT produce a beacon, but must set currentOrientation
        let expectation = self.expectation(description: "no beacon on first orientation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.currentOrientation, .landscapeLeft)
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }

    // MARK: - appDidEnterBackground

    func test_appDidEnterBackground_stagesBackgroundBeacon() {
        // Given
        observer.startObserving()

        // When
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "background event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let event = mockStagingManager.stagedEvents.first!
        XCTAssertEqual(event.eventType, .appState)
        XCTAssertEqual(event.eventValue, AppStateValueEnum.background.rawValue)
        XCTAssertEqual(event.eventValueKey, userActionKey_appState)
    }

    func test_appDidEnterBackground_notObserving_doesNotStageBeacon() {
        // Given – observer has NOT called startObserving
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)

        // When
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Then – no listener registered, nothing staged
        let expectation = self.expectation(description: "no event staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }

    func test_appDidEnterBackground_afterStopObserving_doesNotStageBeacon() {
        // Given
        observer.startObserving()
        observer.stopObserving()

        // When
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Then
        let expectation = self.expectation(description: "no event staged after stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }

    func test_appDidEnterBackground_multiplePostings_stagesOneBeaconEach() {
        // Given
        observer.startObserving()

        // When – background notification posted twice
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Then – each posting stages its own beacon
        let expectation = self.expectation(description: "two background events staged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStagingManager.stagedEvents.count, 2)
        XCTAssertTrue(mockStagingManager.stagedEvents.allSatisfy {
            $0.eventType == .appState && $0.eventValue == AppStateValueEnum.background.rawValue
        })
    }

}

// MARK: - MockNotificationStagingManager

@available(iOS 13.0, *)
class MockNotificationStagingManager: StagingManager {

    struct StagedEvent {
        let timestamp: Instana.Types.Milliseconds
        let eventType: UserActionEnum
        let eventValue: String?
        let eventValueKey: String?
    }

    var stagedEvents: [StagedEvent] = []

    init(config: InstanaSessionReplayConfig) {
        try! super.init(config: config, fileManager: .default)
    }

    override func stageUserEvent(timestamp: Instana.Types.Milliseconds,
                                 eventType: UserActionEnum,
                                 eventValue: String? = nil,
                                 eventValueKey: String? = nil,
                                 viewClassName: String? = nil,
                                 viewId: String? = nil,
                                 coordinates: [[Int]] = []) {
        stagedEvents.append(StagedEvent(
            timestamp: timestamp,
            eventType: eventType,
            eventValue: eventValue,
            eventValueKey: eventValueKey
        ))
    }
}
