//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
class FrustrationTapDetectorTests: XCTestCase {
    
    var detector: FrustrationTapDetector!
    var mockStagingManager: MockStagingManager!
    
    override func setUp() {
        super.setUp()
        detector = FrustrationTapDetector(
            rageTapCountThreshold: 3,
            rageTapThresholdDistance: 100,
            rageTapThresholdTime: 1400
        )

        // enable relevant sampling so as to trigger frustration detection
        let relevantSamplingConfig = RelevantSamplingConfig(
            enabled: true,
            enableOnEventTypes: [.frustration]
        )
        let samplingConfig = SamplingConfig(
            samplingPercentage: 0,
            relevantSamplingConfig: relevantSamplingConfig
        )
        let config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        mockStagingManager = MockStagingManager(config: config)
    }
    
    override func tearDown() {
        detector = nil
        mockStagingManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withDefaultValues() {
        // When
        let detector = FrustrationTapDetector()
        
        // Then - verify default values are set correctly
        XCTAssertNotNil(detector)
    }
    
    func test_init_withCustomValues() {
        // When
        let detector = FrustrationTapDetector(
            rageTapCountThreshold: 5,
            rageTapThresholdDistance: 50,
            rageTapThresholdTime: 2000
        )
        
        // Then
        XCTAssertNotNil(detector)
    }
    
    // MARK: - Rage Tap Detection Tests
    
    func test_checkRageTap_singleTap_doesNotGenerateRageTapBeacon() {
        // Given
        let timestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: timestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )

        // Then - wait for async operation
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.detector.rageTapTimestamps.count, 1)
            XCTAssertEqual(self.detector.rageTapLocations.count, 1)
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_checkRageTap_twoTaps_doesNotGenerateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 2 taps
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 100,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.detector.rageTapTimestamps.count, 2)
            XCTAssertEqual(self.detector.rageTapLocations.count, 2)
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_checkRageTap_threeTapsInSameLocation_generateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 3 taps in same location
        for i in 0..<3 {
            detector.checkRageTap(
                stagingManager: mockStagingManager,
                timestamp: baseTimestamp + Instana.Types.Milliseconds(i * 100),
                viewClassName: "TestView",
                viewId: "testView1",
                coordinates: coordinates
            )
        }

        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
            let event = self.mockStagingManager.stagedEvents.first!
            XCTAssertEqual(event.eventType, .frustrationSignal)
            XCTAssertEqual(event.eventValue, FrustrationSignalValueEnum.rageTap.rawValue)
            XCTAssertEqual(event.viewClassName, "TestView")
            XCTAssertEqual(event.viewId, "testView1")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_checkRageTap_threeTapsWithinDistanceThreshold_generateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let baseCoordinates = [100, 200]
        
        // When - simulate 3 taps within distance threshold (< 100 pixels)
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: baseCoordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 100,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: [baseCoordinates[0] + 50, baseCoordinates[1] + 50]
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 200,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: [baseCoordinates[0] + 30, baseCoordinates[1] + 30]
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
    }
    
    func test_checkRageTap_threeTapsBeyondDistanceThreshold_doesNotGenerateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let baseCoordinates = [100, 200]
        
        // When - simulate 3 taps beyond distance threshold (>= 100 pixels)
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: baseCoordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 100,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: [baseCoordinates[0] + 150, baseCoordinates[1]]
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 200,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: baseCoordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_checkRageTap_threeTapsBeyondTimeThreshold_doesNotGenerateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 3 taps beyond time threshold (> 1400ms)
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 100,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        // Third tap after time threshold
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 1500,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 0)
    }
    
    func test_checkRageTap_moreThanThreeTaps_generateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 5 taps
        for i in 0..<5 {
            detector.checkRageTap(
                stagingManager: mockStagingManager,
                timestamp: baseTimestamp + Instana.Types.Milliseconds(i * 100),
                viewClassName: "TestView",
                viewId: "testView1",
                coordinates: coordinates
            )
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
    }
        
    func test_checkRageTap_withNilViewClassName_generateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 3 taps with nil viewClassName
        for i in 0..<3 {
            detector.checkRageTap(
                stagingManager: mockStagingManager,
                timestamp: baseTimestamp + Instana.Types.Milliseconds(i * 100),
                viewClassName: nil,
                viewId: "testView1",
                coordinates: coordinates
            )
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
        let event = self.mockStagingManager.stagedEvents.first!
        XCTAssertNil(event.viewClassName)
    }
    
    func test_checkRageTap_withNilViewId_generateRageTapBeacon() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 3 taps with nil viewId
        for i in 0..<3 {
            detector.checkRageTap(
                stagingManager: mockStagingManager,
                timestamp: baseTimestamp + Instana.Types.Milliseconds(i * 100),
                viewClassName: "TestView",
                viewId: nil,
                coordinates: coordinates
            )
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
        let event = self.mockStagingManager.stagedEvents.first!
        XCTAssertNil(event.viewId)
    }
    
    func test_checkRageTap_edgeCaseAtDistanceThreshold() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let baseCoordinates = [100, 200]
        
        // When - simulate 3 taps exactly at distance threshold (99 pixels)
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: baseCoordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 100,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: [baseCoordinates[0] + 99, baseCoordinates[1]]
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 200,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: baseCoordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
    }
    
    func test_checkRageTap_edgeCaseAtTimeThreshold() {
        // Given
        let baseTimestamp: Instana.Types.Milliseconds = 1000
        let coordinates = [100, 200]
        
        // When - simulate 3 taps exactly at time threshold (1400ms)
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 700,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        detector.checkRageTap(
            stagingManager: mockStagingManager,
            timestamp: baseTimestamp + 1400,
            viewClassName: "TestView",
            viewId: "testView1",
            coordinates: coordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(self.mockStagingManager.stagedEvents.count, 1)
    }
}

// MARK: - Mock StagingManager

@available(iOS 13.0, *)
class MockStagingManager: StagingManager {
    
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
    var flushCalled = false
    
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
    
    override func flushSessionReplayData() {
        flushCalled = true
    }
}
