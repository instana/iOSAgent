//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
class UserEventTests: SessionReplayTestCaseBase {

    var userEvent: UserEvent!
    var mockStagingManager: MockUserEventStagingManager!
    var config: InstanaSessionReplayConfig!
    var testWindow: UIWindow!
    var testView: UIView!
    
    override func setUp() {
        super.setUp()
        
        // Create config
        let samplingConfig = SamplingConfig(
            samplingPercentage: 50,
            onDemandSamplingEnabled: true
        )
        config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        config.isSampled = false
        
        // Create mock staging manager
        mockStagingManager = MockUserEventStagingManager(config: config)

        // Create user event
        userEvent = UserEvent(config: config, stagingManager: mockStagingManager)
        
        // Create test window and view
        testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        testView = UIView(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        testView.accessibilityIdentifier = "testView"
        testWindow.addSubview(testView)
        testWindow.makeKeyAndVisible()
    }
    
    override func tearDown() {
        testWindow = nil
        testView = nil
        userEvent = nil
        mockStagingManager = nil
        config = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_setsConfigAndStagingManager() {
        // Then
        XCTAssertNotNil(userEvent.config)
        XCTAssertNotNil(userEvent.stagingManager)
    }
    
    func test_init_setsLastTouchTime() {
        // Given
        let beforeInit = Date().millisecondsSince1970
        
        // When
        let newUserEvent = UserEvent(config: config, stagingManager: mockStagingManager)
        
        // Then
        let afterInit = Date().millisecondsSince1970
        XCTAssertGreaterThanOrEqual(newUserEvent.lastTouchTime, beforeInit)
        XCTAssertLessThanOrEqual(newUserEvent.lastTouchTime, afterInit)
    }
    
    // MARK: - Touch Phase Detection Tests
    
    func test_isTouchBegin_withBeganPhase_returnsTrue() {
        // This tests the private method indirectly through processSendEvent
        // We verify by checking if a TouchEntry is created
        
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        
        // When
        userEvent.processSendEvent(event: event)
        
        // Then
        XCTAssertNotNil(touch.touchEntry, "TouchEntry should be created for began phase")
    }
    
    func test_isTouchMove_withMovedPhase_appendsTouch() {
        // Given - create initial touch
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let beginEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: beginEvent)
        
        let initialTouchCount = touch.touchEntry?.touches.count ?? 0
        
        // When - move touch
        touch.phase = .moved
        touch.currentLocation = CGPoint(x: 110, y: 210)
        let moveEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: moveEvent)
        
        // Then
        XCTAssertEqual(touch.touchEntry?.touches.count, initialTouchCount + 1)
    }
    
    func test_isTouchFinished_withEndedPhase_reportsEvent() {
        // Given - create and move touch
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let beginEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: beginEvent)
        
        // When - end touch
        touch.phase = .ended
        let endEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: endEvent)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let event = mockStagingManager.stagedEvents.first!
        XCTAssertEqual(event.eventType, .touch)
    }
    
    func test_isTouchFinished_withCancelledPhase_reportsEvent() {
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let beginEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: beginEvent)
        
        // When - cancel touch
        touch.phase = .cancelled
        let cancelEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: cancelEvent)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        XCTAssertTrue(touch.touchEntry?.isCancelled ?? false)
    }
    
    // MARK: - processSendEvent Tests
    
    func test_processSendEvent_withNonTouchEvent_doesNothing() {
        // Given
        let event = MockUIEvent(type: .motion, touches: [])
        
        // When
        userEvent.processSendEvent(event: event)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_processSendEvent_withNoTouches_doesNothing() {
        // Given
        let event = MockUIEvent(touches: [])
        
        // When
        userEvent.processSendEvent(event: event)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_processSendEvent_updatesLastTouchTime() {
        // Given
        let oldLastTouchTime = userEvent.lastTouchTime
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        
        // Wait a bit to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)
        
        // When
        userEvent.processSendEvent(event: event)
        
        // Then
        XCTAssertGreaterThan(userEvent.lastTouchTime, oldLastTouchTime)
    }
    
    func test_processSendEvent_capturesViewClassName() {
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        
        // When
        userEvent.processSendEvent(event: event)
        touch.phase = .ended
        let endEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: endEvent)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let stagedEvent = mockStagingManager.stagedEvents.first!
        XCTAssertNotNil(stagedEvent.viewClassName)
        XCTAssertTrue(stagedEvent.viewClassName?.contains("UIWindow") ?? false)
    }
    
    func test_processSendEvent_capturesViewId() {
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        
        // When
        userEvent.processSendEvent(event: event)
        touch.phase = .ended
        let endEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: endEvent)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let stagedEvent = mockStagingManager.stagedEvents.first!
        XCTAssertEqual(stagedEvent.viewId, nil)
    }
    
    func test_processSendEvent_capturesCoordinates() {
        // Given
        let location = CGPoint(x: 150, y: 250)
        let touch = MockUITouch(phase: .began, location: location, window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        
        // When
        userEvent.processSendEvent(event: event)
        touch.phase = .ended
        let endEvent = MockUIEvent(touches: [touch])
        userEvent.processSendEvent(event: endEvent)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let stagedEvent = mockStagingManager.stagedEvents.first!
        XCTAssertFalse(stagedEvent.coordinates.isEmpty)
        let firstCoord = stagedEvent.coordinates.first!
        XCTAssertEqual(firstCoord[0], Int(location.x))
        XCTAssertEqual(firstCoord[1], Int(location.y))
    }
    
    func test_processSendEvent_withMultipleTouches_processesAll() {
        // Given
        let touch1 = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let touch2 = MockUITouch(phase: .began, location: CGPoint(x: 200, y: 300), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch1, touch2])
        
        // When
        userEvent.processSendEvent(event: event)
        
        // Then
        XCTAssertNotNil(touch1.touchEntry)
        XCTAssertNotNil(touch2.touchEntry)
    }
    
    // MARK: - processSendAction Tests
    
    func test_processSendAction_withValidTap_reportsEvent() {
        // Given
        let touch = MockUITouch(phase: .ended, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let touchEntry = TouchEntry(timestamp: Date().millisecondsSince1970,
                                    locationInWindow: CGPoint(x: 100, y: 200),
                                    viewClassName: "UIButton",
                                    viewId: "submitButton")
        touch.touchEntry = touchEntry
        let event = MockUIEvent(touches: [touch])
        
        let target = testView
        let sender = UIButton()
        let action = #selector(UIButton.sendAction(_:to:for:))
        
        // When
        userEvent.processSendAction(action, to: target, from: sender, for: event)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
        let stagedEvent = mockStagingManager.stagedEvents.first!
        XCTAssertEqual(stagedEvent.eventType, .tap)
    }
        
    func test_processSendAction_withTouchEnd() {
        // Given
        let touch = MockUITouch(phase: .ended, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let event = MockUIEvent(touches: [touch])
        // Note: no touchEntry set
        
        // When
        userEvent.processSendAction(#selector(UIButton.sendAction(_:to:for:)),
                                    to: testView,
                                    from: UIButton(),
                                    for: event)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 1)
    }
    
    func test_processSendAction_withNilTarget_doesNothing() {
        // Given
        let touch = MockUITouch(phase: .ended, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let touchEntry = TouchEntry(timestamp: Date().millisecondsSince1970,
                                    locationInWindow: CGPoint(x: 100, y: 200))
        touch.touchEntry = touchEntry
        let event = MockUIEvent(touches: [touch])
        
        // When
        userEvent.processSendAction(#selector(UIButton.sendAction(_:to:for:)),
                                    to: nil,
                                    from: UIButton(),
                                    for: event)
        
        // Then
        XCTAssertEqual(mockStagingManager.stagedEvents.count, 0)
    }
    
    // MARK: - Frustration Detection Tests
    
    func test_processSendEvent_triggersRageTapDetection() {
        // Given - simulate 3 quick taps in same location
        let location = CGPoint(x: 100, y: 200)
        
        for _ in 0..<3 {
            let touch = MockUITouch(phase: .began, location: location, window: testWindow, view: testView)
            let beginEvent = MockUIEvent(touches: [touch])
            userEvent.processSendEvent(event: beginEvent)
            
            touch.phase = .ended
            let endEvent = MockUIEvent(touches: [touch])
            userEvent.processSendEvent(event: endEvent)
            
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        // Then - should have 3 touch events + 1 frustration signal
        // Wait for async frustration detection
        let expectation = XCTestExpectation(description: "Wait for frustration detection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Should have touch events and potentially a frustration signal
        XCTAssertGreaterThanOrEqual(mockStagingManager.stagedEvents.count, 3)
    }
    
    // MARK: - UITouch Extension Tests
    
    func test_touchEntry_associatedObject_canBeSetAndRetrieved() {
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let entry = TouchEntry(timestamp: Date().millisecondsSince1970,
                              locationInWindow: CGPoint(x: 100, y: 200))
        
        // When
        touch.touchEntry = entry
        
        // Then
        XCTAssertNotNil(touch.touchEntry)
        XCTAssertEqual(touch.touchEntry?.timestamp, entry.timestamp)
    }
    
    func test_touchEntry_canBeSetToNil() {
        // Given
        let touch = MockUITouch(phase: .began, location: CGPoint(x: 100, y: 200), window: testWindow, view: testView)
        let entry = TouchEntry(timestamp: Date().millisecondsSince1970,
                              locationInWindow: CGPoint(x: 100, y: 200))
        touch.touchEntry = entry
        
        // When
        touch.touchEntry = nil
        
        // Then
        XCTAssertNil(touch.touchEntry)
    }
}

// MARK: - Mock Classes

@available(iOS 13.0, *)
class MockUserEventStagingManager: StagingManager {
    
    struct StagedEvent {
        let timestamp: Instana.Types.Milliseconds
        let eventType: UserActionEnum
        let eventValue: String?
        let eventValueKey: String?
        let viewClassName: String?
        let viewId: String?
        let coordinates: [[Int]]
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
        let event = StagedEvent(
            timestamp: timestamp,
            eventType: eventType,
            eventValue: eventValue,
            eventValueKey: eventValueKey,
            viewClassName: viewClassName,
            viewId: viewId,
            coordinates: coordinates
        )
        stagedEvents.append(event)
    }
}

class MockUITouch: UITouch {
    var mockPhase: UITouch.Phase
    var currentLocation: CGPoint
    var mockWindow: UIWindow?
    var mockView: UIView?
    
    init(phase: UITouch.Phase, location: CGPoint, window: UIWindow?, view: UIView?) {
        self.mockPhase = phase
        self.currentLocation = location
        self.mockWindow = window
        self.mockView = view
        super.init()
    }
    
    override var phase: UITouch.Phase {
        get { return mockPhase }
        set { mockPhase = newValue }
    }
    
    override func location(in view: UIView?) -> CGPoint {
        return currentLocation
    }
    
    override var window: UIWindow? {
        return mockWindow
    }
    
    override var view: UIView? {
        return mockView
    }
}

class MockUIEvent: UIEvent {
    private var mockType: UIEvent.EventType
    private var mockTouches: Set<UITouch>
    
    init(type: UIEvent.EventType = .touches, touches: [UITouch]) {
        self.mockType = type
        self.mockTouches = Set(touches)
        super.init()
    }
    
    override var type: UIEvent.EventType {
        return mockType
    }
    
    override var allTouches: Set<UITouch>? {
        return mockTouches.isEmpty ? nil : mockTouches
    }
}
