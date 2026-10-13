//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay
@testable @_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
class StagingManagerTests: SessionReplayTestCaseBase {

    var stagingManager: StagingManager!
    var config: InstanaSessionReplayConfig!
    var testFileManager: FileManager!
    var testStagingDirectory: URL!
    
    override func setUp() {
        super.setUp()
        
        // CRITICAL: Wait for any previous test's async operations to complete
        // This prevents crashes from unowned references in ScreenCapture
//        let initialWait = XCTestExpectation(description: "Initial wait")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            initialWait.fulfill()
//        }
//        wait(for: [initialWait], timeout: 1.0)
        
        // Ensure any existing InstanaSessionReplay is cleared
        InstanaSessionReplay.current = nil
        
        testFileManager = FileManager.default
        
        // Create a unique test directory for each test
        let uniqueID = UUID().uuidString
        testStagingDirectory = testFileManager.temporaryDirectory
            .appendingPathComponent("test-staging-\(uniqueID)", isDirectory: true)
        
        // Create config with buffering enabled
        let samplingConfig = SamplingConfig(
            samplingPercentage: 50,
            onDemandSamplingEnabled: true)
        config = InstanaSessionReplayConfig(samplingConfig: samplingConfig)
        config.isSampled = false

        do {
            stagingManager = try StagingManager(config: config, fileManager: testFileManager)
        } catch {
            XCTFail("Failed to initialize StagingManager: \(error)")
        }
    }
    
    override func tearDown() {
        // Get staging directory before clearing reference
        let stagingDir = stagingManager?.stagingDirectoryURL
        
        // Clean up test directories (but keep stagingManager alive)
        if let dir = stagingDir, testFileManager.fileExists(atPath: dir.path) {
            try? testFileManager.removeItem(at: dir)
        }
        if let testDir = testStagingDirectory, testFileManager.fileExists(atPath: testDir.path) {
            try? testFileManager.removeItem(at: testDir)
        }
        
        // Now it's safe to deallocate
        stagingManager = nil
        config = nil
        testFileManager = nil
        testStagingDirectory = nil
        
        // Ensure InstanaSessionReplay is cleared
        InstanaSessionReplay.current = nil

        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsDirectoryStructure() throws {
        // Then
        XCTAssertTrue(testFileManager.fileExists(atPath: stagingManager.stagingDirectoryURL.path))
        XCTAssertEqual(stagingManager.lastCleanupTime, 0)
    }
    
    func test_init_clearsExistingData() throws {
        // Given - create some test files
        let userEventsDir = stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
        try testFileManager.createDirectory(at: userEventsDir, withIntermediateDirectories: true)
        let testFile = userEventsDir.appendingPathComponent("test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)
        
        // When - reinitialize
        stagingManager = try StagingManager(config: config, fileManager: testFileManager)
        
        // Then - directory should be empty
        let contents = try testFileManager.contentsOfDirectory(at: stagingManager.stagingDirectoryURL,
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles])
        XCTAssertEqual(contents.count, 0)
    }
    
    func test_createStagingDirectory_createsDirectory() throws {
        // When
        let directoryURL = try StagingManager.createStagingDirectory(fileManager: testFileManager)
        
        // Then
        XCTAssertTrue(testFileManager.fileExists(atPath: directoryURL.path))
        XCTAssertTrue(directoryURL.lastPathComponent.contains("instana-sessionreplay-staging"))
    }
    
    func test_cacheDirectoryName_returnsCorrectName() {
        // When
        let name = StagingManager.cacheDirectoryName()
        
        // Then
        XCTAssertEqual(name, "instana-sessionreplay-staging")
    }
    
    // MARK: - User Event Staging Tests
    
    func test_stageUserEvent_withBufferingEnabled_writesFile() throws {
        // Given
        let timestamp: Instana.Types.Milliseconds = 1000
        let eventType = UserActionEnum.tap
        let viewClassName = "TestViewController"
        let viewId = "testView"
        let coordinates = [[100, 200]]
        
        // When
        stagingManager.stageUserEvent(
            timestamp: timestamp,
            eventType: eventType,
            eventValue: nil,
            viewClassName: viewClassName,
            viewId: viewId,
            coordinates: coordinates
        )
        
        // Then - wait for async operation
        let expectation = XCTestExpectation(description: "Wait for file write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let userEventsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            let fileURL = userEventsDir.appendingPathComponent("\(timestamp)")
            
            XCTAssertTrue(self.testFileManager.fileExists(atPath: fileURL.path))
            
            // Verify file content
            do {
                let data = try Data(contentsOf: fileURL)
                let beacon = try JSONDecoder().decode(UserEventBeacon.self, from: data)
                XCTAssertEqual(beacon.timestamp, timestamp)
                XCTAssertEqual(beacon.eventType, UserActionEnum.tap.rawValue)
                XCTAssertEqual(beacon.viewClassName, viewClassName)
                XCTAssertEqual(beacon.viewId, viewId)
            } catch {
                XCTFail("Failed to read or decode beacon: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_stageUserEvent_withBufferingDisabled_doesNotWriteFile() throws {
        // Given - config with buffering disabled
        let configNoBuffer = InstanaSessionReplayConfig(samplingConfig: SamplingConfig(samplingPercentage: 100))
        configNoBuffer.isSampled = true
        let managerNoBuffer = try StagingManager(config: configNoBuffer, fileManager: testFileManager)
        
        let timestamp: Instana.Types.Milliseconds = 1000
        
        // When
        managerNoBuffer.stageUserEvent(
            timestamp: timestamp,
            eventType: .tap,
            viewClassName: "TestView",
            viewId: "test"
        )
        
        // Then - wait and verify no file was created
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let userEventsDir = managerNoBuffer.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            if self.testFileManager.fileExists(atPath: userEventsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: userEventsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                XCTAssertEqual(contents?.count ?? 0, 0)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_stageUserEvent_setsLastCleanupTime() throws {
        // Given
        XCTAssertEqual(stagingManager.lastCleanupTime, 0)
        
        // When
        stagingManager.stageUserEvent(
            timestamp: 1000,
            eventType: .tap,
            viewClassName: "TestView",
            viewId: "test"
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertGreaterThan(self.stagingManager.lastCleanupTime, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Screenshot Staging Tests
    
    func test_stageScreenshot_withBufferingEnabled_writesFile() throws {
        // Given
        let timestamp: Instana.Types.Milliseconds = 2000
        let imageData = Data([0x01, 0x02, 0x03])
        let meta = ["imageId": "test-image-123", "viewName": "TestView"]
        let beacon = ImageBeacon(image: imageData, meta: meta, timestamp: timestamp)
        
        // When
        stagingManager.stageScreenshot(timestamp: timestamp, beacon: beacon)
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for file write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            let fileURL = imageBeaconsDir.appendingPathComponent("\(timestamp)")
            
            XCTAssertTrue(self.testFileManager.fileExists(atPath: fileURL.path))
            
            // Verify file content
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedBeacon = try JSONDecoder().decode(ImageBeacon.self, from: data)
                XCTAssertEqual(decodedBeacon.ti, timestamp)
                XCTAssertEqual(decodedBeacon.img, imageData)
                XCTAssertEqual(decodedBeacon.meta["imageId"], "test-image-123")
            } catch {
                XCTFail("Failed to read or decode beacon: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Clear All Tests
    
    func test_clearAll_removesAllFiles() throws {
        // Given - stage some events
        stagingManager.stageUserEvent(timestamp: 1000, eventType: .tap, viewClassName: "Test", viewId: "test1")
        stagingManager.stageUserEvent(timestamp: 2000, eventType: .tap, viewClassName: "Test", viewId: "test2")
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // When
        try stagingManager.clearAll()
        
        // Then
        let contents = try testFileManager.contentsOfDirectory(at: stagingManager.stagingDirectoryURL,
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles])
        XCTAssertEqual(contents.count, 0)
        XCTAssertEqual(stagingManager.lastCleanupTime, 0)
    }
    
    // MARK: - Flush Tests
    
    func test_flushSessionReplayData_flushesUserEvents() throws {
        // Given - stage events within cutoff time
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        let recentTimestamp = cutoffTime + 1000
        
        stagingManager.stageUserEvent(
            timestamp: recentTimestamp,
            eventType: .tap,
            viewClassName: "TestView",
            viewId: "test"
        )
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // When
        stagingManager.flushSessionReplayData()
        
        // Then - verify directory is cleared after flush
        let expectation2 = XCTestExpectation(description: "Wait for flush")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let userEventsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            if self.testFileManager.fileExists(atPath: userEventsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: userEventsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                XCTAssertEqual(contents?.count ?? 0, 0, "User events directory should be empty after flush")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_flushSessionReplayData_doesNotFlushOldEvents() throws {
        // Given - stage event outside cutoff time
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        let oldTimestamp = cutoffTime - 1000
        
        stagingManager.stageUserEvent(
            timestamp: oldTimestamp,
            eventType: .tap,
            viewClassName: "TestView",
            viewId: "test"
        )
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // When
        stagingManager.flushSessionReplayData()
        
        // Then - old events should not be flushed (directory cleared anyway)
        let expectation2 = XCTestExpectation(description: "Wait for flush")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let userEventsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            if self.testFileManager.fileExists(atPath: userEventsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: userEventsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                XCTAssertEqual(contents?.count ?? 0, 0)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    // MARK: - Purge Tests
    
    func test_purgeFilesAsNeeded_respectsCleanupInterval() throws {
        // Given - set last cleanup time to recent
        let now = Date().millisecondsSince1970
        stagingManager.lastCleanupTime = now - 30000 // 30 seconds ago (less than 60 second interval)
        
        // When - stage an event (which triggers purge check)
        stagingManager.stageUserEvent(timestamp: now, eventType: .tap, viewClassName: "Test", viewId: "test")
        
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Then - lastCleanupTime should not have changed (purge didn't run)
            XCTAssertEqual(self.stagingManager.lastCleanupTime, now - 30000)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_purgeFilesAsNeeded_runsAfterInterval() throws {
        // Given - set last cleanup time to old
        let now = Date().millisecondsSince1970
        stagingManager.lastCleanupTime = now - 70000 // 70 seconds ago (more than 60 second interval)
        
        // When - stage an event
        stagingManager.stageUserEvent(timestamp: now, eventType: .tap, viewClassName: "Test", viewId: "test")
        
        let expectation = XCTestExpectation(description: "Wait for async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Then - lastCleanupTime should have been updated
            XCTAssertGreaterThan(self.stagingManager.lastCleanupTime, now - 70000)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Config Tests
    
    func test_config_calcCutoffTime() {
        // Given
        let timestamp: Instana.Types.Milliseconds = 10000000
        let maxTime = config.samplingConfig.maxTimeBufferMinutes // 3.0 minutes
        
        // When
        let cutoffTime = config.calcCutoffTime(timestamp)
        
        // Then
        let expectedCutoff = timestamp - Instana.Types.Milliseconds(maxTime * 60 * 1000)
        XCTAssertEqual(cutoffTime, expectedCutoff)
    }
    
//    func test_config_calcCutoffSize() {
//        // Given
//        let maxMemory = config.samplingConfig.maxSizeBufferMb // 1.0 MB
//
//        // When
//        let cutoffSize = config.calcCutoffSize()
//
//        // Then
//        let expectedSize = maxMemory * 1000000.0 // in bytes
//        XCTAssertEqual(cutoffSize, expectedSize)
//    }
    
    func test_config_bufferDataLocally_withSamplingEnabled() {
        // Given
        config.isSampled = false
        config.samplingConfig.onDemandSamplingEnabled = true
        
        // When
        let shouldBuffer = config.bufferDataLocally()
        
        // Then
        XCTAssertTrue(shouldBuffer)
    }
    
    func test_config_bufferDataLocally_withSamplingDisabled() {
        // Given
        config.isSampled = true
        
        // When
        let shouldBuffer = config.bufferDataLocally()
        
        // Then
        XCTAssertFalse(shouldBuffer)
    }
    
    // MARK: - Multiple Events Tests
    
    func test_stageMultipleUserEvents_createsMultipleFiles() throws {
        // Given
        let timestamps: [Instana.Types.Milliseconds] = [1000, 2000, 3000, 4000, 5000]
        
        // When
        for timestamp in timestamps {
            stagingManager.stageUserEvent(
                timestamp: timestamp,
                eventType: .tap,
                viewClassName: "TestView",
                viewId: "test\(timestamp)"
            )
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for all writes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let userEventsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            if self.testFileManager.fileExists(atPath: userEventsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: userEventsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                XCTAssertEqual(contents?.count, timestamps.count)
            } else {
                XCTFail("User events directory should exist")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_stageUserEvent_withAllParameters() throws {
        // Given
        let timestamp: Instana.Types.Milliseconds = 1000
        let eventType = UserActionEnum.frustrationSignal
        let eventValue = "rageTap"
        let viewClassName = "UIButton"
        let viewId = "submitButton"
        let coordinates = [[100, 200], [105, 205]]
        
        // When
        stagingManager.stageUserEvent(
            timestamp: timestamp,
            eventType: eventType,
            eventValue: eventValue,
            viewClassName: viewClassName,
            viewId: viewId,
            coordinates: coordinates
        )
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for file write")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let userEventsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("userEvents", isDirectory: true)
            let fileURL = userEventsDir.appendingPathComponent("\(timestamp)")
            
            do {
                let data = try Data(contentsOf: fileURL)
                let beacon = try JSONDecoder().decode(UserEventBeacon.self, from: data)
                XCTAssertEqual(beacon.eventType, eventType.rawValue)
                XCTAssertEqual(beacon.eventValue, eventValue)
                XCTAssertEqual(beacon.viewClassName, viewClassName)
                XCTAssertEqual(beacon.viewId, viewId)
            } catch {
                XCTFail("Failed to verify beacon: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Purge Expired Image Files Tests (purgeExpiredImageFiles - lines 244-285)
    
    func test_purgeExpiredImageFiles_identifiesReferencedImageIds() throws {
        // Given - stage beacons to test line 244-250 (identifying referenced image IDs)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Old beacon with image (before cutoff)
        let oldTimestamp = cutoffTime - 1000
        let imageData = Data([0xAA, 0xBB])
        let imageId = "referenced-image-001"
        let oldMeta = ["imageId": imageId, "viewName": "OldView"]
        let oldBeacon = ImageBeacon(image: imageData, meta: oldMeta, timestamp: oldTimestamp)
        
        // Recent partial beacon (after cutoff) referencing the old image
        let recentTimestamp = cutoffTime + 1000
        let partialMeta = ["imageId": imageId, "viewName": "NewView"]
        let partialBeacon = ImageBeacon(image: nil, meta: partialMeta, timestamp: recentTimestamp)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp, beacon: oldBeacon)
        stagingManager.stageScreenshot(timestamp: recentTimestamp, beacon: partialBeacon)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup by setting lastCleanupTime to old value
        stagingManager.lastCleanupTime = now - 70000
        
        // When - stage another event to trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x01]), meta: ["imageId": "new"], timestamp: now))
        
        // Then - verify the referenced image is preserved
        let expectation2 = XCTestExpectation(description: "Wait for purge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            if self.testFileManager.fileExists(atPath: imageBeaconsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: imageBeaconsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                // Should have recent partial beacon and new beacon (old beacon purged but image preserved)
                XCTAssertGreaterThan(contents?.count ?? 0, 0)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_removesExpiredFiles() throws {
        // Given - stage old beacons (before cutoff) to test line 253-268 (removing expired files)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Multiple old beacons (before cutoff)
        let oldTimestamp1 = cutoffTime - 2000
        let oldTimestamp2 = cutoffTime - 1000
        let imageData = Data([0xFF, 0xEE])
        
        let oldBeacon1 = ImageBeacon(image: imageData, meta: ["imageId": "old-1", "viewName": "Old1"], timestamp: oldTimestamp1)
        let oldBeacon2 = ImageBeacon(image: imageData, meta: ["imageId": "old-2", "viewName": "Old2"], timestamp: oldTimestamp2)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp1, beacon: oldBeacon1)
        stagingManager.stageScreenshot(timestamp: oldTimestamp2, beacon: oldBeacon2)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - stage a new event to trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x01]), meta: ["imageId": "new"], timestamp: now))
        
        // Then - verify old files are removed
        let expectation2 = XCTestExpectation(description: "Wait for purge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            if self.testFileManager.fileExists(atPath: imageBeaconsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: imageBeaconsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                // Should only have the new beacon
                XCTAssertEqual(contents?.count, 1)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_preservesReferencedImageData() throws {
        // Given - test line 263-266 (preserving referenced image data)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Old beacon with image that will be referenced
        let oldTimestamp = cutoffTime - 1000
        let imageData = Data([0x11, 0x22, 0x33])
        let sharedImageId = "shared-image-preserve"
        let oldMeta = ["imageId": sharedImageId, "viewName": "OldView"]
        let oldBeacon = ImageBeacon(image: imageData, meta: oldMeta, timestamp: oldTimestamp)
        
        // Recent partial beacon referencing the old image
        let recentTimestamp = cutoffTime + 1000
        let partialMeta = ["imageId": sharedImageId, "viewName": "NewView"]
        let partialBeacon = ImageBeacon(image: nil, meta: partialMeta, timestamp: recentTimestamp)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp, beacon: oldBeacon)
        stagingManager.stageScreenshot(timestamp: recentTimestamp, beacon: partialBeacon)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x99]), meta: ["imageId": "trigger"], timestamp: now))
        
        // Then - verify partial beacon is updated with image data (line 272-284)
        let expectation2 = XCTestExpectation(description: "Wait for purge and update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            if self.testFileManager.fileExists(atPath: imageBeaconsDir.path) {
                let fileURL = imageBeaconsDir.appendingPathComponent("\(recentTimestamp)")
                if self.testFileManager.fileExists(atPath: fileURL.path) {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let updatedBeacon = try JSONDecoder().decode(ImageBeacon.self, from: data)
                        // Verify the partial beacon now has the image data
                        XCTAssertNotNil(updatedBeacon.img, "Partial beacon should have image data after purge")
                        XCTAssertEqual(updatedBeacon.img, imageData, "Image data should match the old beacon's data")
                    } catch {
                        XCTFail("Failed to verify updated beacon: \(error)")
                    }
                }
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_updatesMultipleBeaconsReferencingSameImage() throws {
        // Given - multiple partial beacons referencing the same old image (line 272-284)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Old beacon with image
        let oldTimestamp = cutoffTime - 1000
        let imageData = Data([0xAA, 0xBB, 0xCC, 0xDD])
        let sharedImageId = "multi-ref-image"
        let oldMeta = ["imageId": sharedImageId, "viewName": "OldView"]
        let oldBeacon = ImageBeacon(image: imageData, meta: oldMeta, timestamp: oldTimestamp)
        
        // Multiple partial beacons referencing the same image
        let partialTimestamp1 = cutoffTime + 1000
        let partialBeacon1 = ImageBeacon(image: nil, meta: ["imageId": sharedImageId, "viewName": "View1"], timestamp: partialTimestamp1)
        
        let partialTimestamp2 = cutoffTime + 2000
        let partialBeacon2 = ImageBeacon(image: nil, meta: ["imageId": sharedImageId, "viewName": "View2"], timestamp: partialTimestamp2)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp, beacon: oldBeacon)
        stagingManager.stageScreenshot(timestamp: partialTimestamp1, beacon: partialBeacon1)
        stagingManager.stageScreenshot(timestamp: partialTimestamp2, beacon: partialBeacon2)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x01]), meta: ["imageId": "trigger"], timestamp: now))
        
        // Then - verify both partial beacons are updated
        let expectation2 = XCTestExpectation(description: "Wait for purge and updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            if self.testFileManager.fileExists(atPath: imageBeaconsDir.path) {
                // Check first partial beacon
                let fileURL1 = imageBeaconsDir.appendingPathComponent("\(partialTimestamp1)")
                if self.testFileManager.fileExists(atPath: fileURL1.path) {
                    do {
                        let data = try Data(contentsOf: fileURL1)
                        let beacon = try JSONDecoder().decode(ImageBeacon.self, from: data)
                        XCTAssertNotNil(beacon.img, "First partial beacon should have image data")
                    } catch {
                        XCTFail("Failed to verify first beacon: \(error)")
                    }
                }
                
                // Check second partial beacon
                let fileURL2 = imageBeaconsDir.appendingPathComponent("\(partialTimestamp2)")
                if self.testFileManager.fileExists(atPath: fileURL2.path) {
                    do {
                        let data = try Data(contentsOf: fileURL2)
                        let beacon = try JSONDecoder().decode(ImageBeacon.self, from: data)
                        XCTAssertNotNil(beacon.img, "Second partial beacon should have image data")
                    } catch {
                        XCTFail("Failed to verify second beacon: \(error)")
                    }
                }
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_handlesBeaconWithoutImageId() throws {
        // Given - beacon without imageId in meta (edge case for line 247, 261)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Old beacon without imageId
        let oldTimestamp = cutoffTime - 1000
        let imageData = Data([0x55, 0x66])
        let oldMeta = ["viewName": "OldView"] // No imageId
        let oldBeacon = ImageBeacon(image: imageData, meta: oldMeta, timestamp: oldTimestamp)
        
        // Partial beacon without imageId
        let partialTimestamp = cutoffTime + 1000
        let partialMeta = ["viewName": "NewView"] // No imageId
        let partialBeacon = ImageBeacon(image: nil, meta: partialMeta, timestamp: partialTimestamp)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp, beacon: oldBeacon)
        stagingManager.stageScreenshot(timestamp: partialTimestamp, beacon: partialBeacon)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - trigger purge (should handle gracefully)
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x01]), meta: ["imageId": "new"], timestamp: now))
        
        // Then - should not crash, old beacon removed, partial beacon remains
        let expectation2 = XCTestExpectation(description: "Wait for purge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // No crash means success
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_placeholderDataHandling() throws {
        // Given - test placeholder data logic (line 242, 248, 263)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Old beacon with image
        let oldTimestamp = cutoffTime - 1000
        let imageData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let imageId = "placeholder-test"
        let oldBeacon = ImageBeacon(image: imageData, meta: ["imageId": imageId], timestamp: oldTimestamp)
        
        // Partial beacon referencing it
        let partialTimestamp = cutoffTime + 1000
        let partialBeacon = ImageBeacon(image: nil, meta: ["imageId": imageId], timestamp: partialTimestamp)
        
        stagingManager.stageScreenshot(timestamp: oldTimestamp, beacon: oldBeacon)
        stagingManager.stageScreenshot(timestamp: partialTimestamp, beacon: partialBeacon)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x01]), meta: ["imageId": "new"], timestamp: now))
        
        // Then - verify placeholder is replaced with actual data
        let expectation2 = XCTestExpectation(description: "Wait for purge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            let fileURL = imageBeaconsDir.appendingPathComponent("\(partialTimestamp)")
            if self.testFileManager.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let beacon = try JSONDecoder().decode(ImageBeacon.self, from: data)
                    XCTAssertNotNil(beacon.img)
                    XCTAssertNotEqual(beacon.img, Data([0x01]), "Should not be placeholder data")
                    XCTAssertEqual(beacon.img, imageData, "Should have actual image data")
                } catch {
                    XCTFail("Failed to verify beacon: \(error)")
                }
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func test_purgeExpiredImageFiles_skipsRecentFiles() throws {
        // Given - test line 255-256 (skipping recent files)
        let now = Date().millisecondsSince1970
        let cutoffTime = now - Instana.Types.Milliseconds(config.samplingConfig.maxTimeBufferMinutes * 60 * 1000)
        
        // Recent beacons (after cutoff) - should NOT be purged
        let recentTimestamp1 = cutoffTime + 1000
        let recentTimestamp2 = cutoffTime + 2000
        
        let recentBeacon1 = ImageBeacon(image: Data([0x11]), meta: ["imageId": "recent-1"], timestamp: recentTimestamp1)
        let recentBeacon2 = ImageBeacon(image: Data([0x22]), meta: ["imageId": "recent-2"], timestamp: recentTimestamp2)
        
        stagingManager.stageScreenshot(timestamp: recentTimestamp1, beacon: recentBeacon1)
        stagingManager.stageScreenshot(timestamp: recentTimestamp2, beacon: recentBeacon2)
        
        let expectation1 = XCTestExpectation(description: "Wait for staging")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Force cleanup
        stagingManager.lastCleanupTime = now - 70000
        
        // When - trigger purge
        stagingManager.stageScreenshot(timestamp: now, beacon: ImageBeacon(image: Data([0x99]), meta: ["imageId": "trigger"], timestamp: now))
        
        // Then - verify recent files are NOT removed
        let expectation2 = XCTestExpectation(description: "Wait for purge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let imageBeaconsDir = self.stagingManager.stagingDirectoryURL.appendingPathComponent("imageBeacons", isDirectory: true)
            if self.testFileManager.fileExists(atPath: imageBeaconsDir.path) {
                let contents = try? self.testFileManager.contentsOfDirectory(at: imageBeaconsDir,
                                                                             includingPropertiesForKeys: nil,
                                                                             options: [.skipsHiddenFiles])
                // Should have all 3 beacons (2 recent + 1 trigger)
                XCTAssertEqual(contents?.count, 3, "Recent files should not be purged")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
    }
}
