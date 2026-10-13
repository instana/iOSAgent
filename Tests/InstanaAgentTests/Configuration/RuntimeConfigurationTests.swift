//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class RuntimeConfigurationTests: InstanaTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: configSessionReplayStateKey)
        UserDefaults.standard.removeObject(forKey: configServerSideTimeStampKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: configSessionReplayStateKey)
        UserDefaults.standard.removeObject(forKey: configServerSideTimeStampKey)
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialValues_whenUserDefaultsEmpty() {
        let runtimeConfig = RuntimeConfiguration()

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 0)
    }

    func test_initialValues_loadedFromUserDefaults() {
        UserDefaults.standard.set(RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue, forKey: configSessionReplayStateKey)
        UserDefaults.standard.set(Int64(1787293426658), forKey: configServerSideTimeStampKey)

        let runtimeConfig = RuntimeConfiguration()

        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
    }

    func test_initialValues_invalidUserDefaultsState_fallsBackToDefault() {
        UserDefaults.standard.set(999, forKey: configSessionReplayStateKey)

        let runtimeConfig = RuntimeConfiguration()

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
    }

    // MARK: - Update & Persistence Tests

    func test_update_withNewerTimestamp_persistsAndPostsNotification() {
        let runtimeConfig = RuntimeConfiguration()
        let expectation = expectation(forNotification: .runtimeConfigurationUpdated, object: runtimeConfig)

        runtimeConfig.update { state in
            state.srServerConfig = .enabled
            state.configurationTimeStamp = 1000
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1000)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1000)
    }

    func test_update_withOlderOrEqualTimestamp_restoresConfigAndDoesNotPersistOrNotify() {
        let runtimeConfig = RuntimeConfiguration()

        // First update: set timestamp to 1000 and status to enabled
        runtimeConfig.update { state in
            state.srServerConfig = .enabled
            state.configurationTimeStamp = 1000
        }

        var notificationFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: .runtimeConfigurationUpdated,
            object: runtimeConfig,
            queue: nil
        ) { _ in
            notificationFired = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // Second update: try to set disabled with older timestamp (500)
        runtimeConfig.update { state in
            state.srServerConfig = .disabled
            state.configurationTimeStamp = 500
        }

        XCTAssertFalse(notificationFired)
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 500)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1000)

        // Third update: try to set disabled with equal timestamp (500)
        runtimeConfig.update { state in
            state.srServerConfig = .disabled
            state.configurationTimeStamp = 500
        }

        XCTAssertFalse(notificationFired)
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 500)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1000)
    }

    // MARK: - handleSRConfigResponse Tests

    func test_handleSRConfigResponse_nilData_doesNothing() {
        let runtimeConfig = RuntimeConfiguration()

        runtimeConfig.handleSRConfigResponse(data: nil)

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 0)
    }

    func test_handleSRConfigResponse_invalidJSON_doesNothing() {
        let runtimeConfig = RuntimeConfiguration()
        let invalidData = "not a json string".data(using: .utf8)

        runtimeConfig.handleSRConfigResponse(data: invalidData)

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 0)
    }

    func test_handleSRConfigResponse_missingSessionReplayConfigKey_doesNothing() {
        let runtimeConfig = RuntimeConfiguration()
        // Wrong format — no "sessionReplayConfig" wrapper
        let jsonString = "{\"status\":\"enabled\",\"lastUpdated\":1787293426658}"
        let data = jsonString.data(using: .utf8)

        runtimeConfig.handleSRConfigResponse(data: data)

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 0)
    }

    func test_handleSRConfigResponse_validEnabledJSON() {
        let runtimeConfig = RuntimeConfiguration()
        let jsonString = "{\"sessionReplayConfig\":{\"status\":\"enabled\",\"lastUpdated\":1787293426658}}"
        let data = jsonString.data(using: .utf8)

        let expectation = expectation(forNotification: .runtimeConfigurationUpdated, object: runtimeConfig)

        runtimeConfig.handleSRConfigResponse(data: data)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1787293426658)
    }

    func test_handleSRConfigResponse_validDisabledJSON() {
        let runtimeConfig = RuntimeConfiguration()
        let jsonString = "{\"sessionReplayConfig\":{\"status\":\"disabled\",\"lastUpdated\":1787293426658}}"
        let data = jsonString.data(using: .utf8)

        let expectation = expectation(forNotification: .runtimeConfigurationUpdated, object: runtimeConfig)

        runtimeConfig.handleSRConfigResponse(data: data)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(runtimeConfig.srServerConfig, .disabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.disabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1787293426658)
    }

    func test_handleSRConfigResponse_validDefaultJSON() {
        let runtimeConfig = RuntimeConfiguration()
        let jsonString = "{\"sessionReplayConfig\":{\"status\":\"default\",\"lastUpdated\":1787293426658}}"
        let data = jsonString.data(using: .utf8)

        let expectation = expectation(forNotification: .runtimeConfigurationUpdated, object: runtimeConfig)

        runtimeConfig.handleSRConfigResponse(data: data)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.srDefault.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 1787293426658)
    }

    func test_handleSRConfigResponse_caseInsensitiveKeysAndValues() {
        let runtimeConfig = RuntimeConfiguration()
        let jsonString = "{\"SESSIONREPLAYCONFIG\":{\"STATUS\":\"EnAbLeD\",\"LASTUPDATED\":1787293426658}}"
        let data = jsonString.data(using: .utf8)

        let expectation = expectation(forNotification: .runtimeConfigurationUpdated, object: runtimeConfig)

        runtimeConfig.handleSRConfigResponse(data: data)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
    }

    func test_handleSRConfigResponse_unknownStatus_setsDefault() {
        let runtimeConfig = RuntimeConfiguration()
        let jsonString = "{\"sessionReplayConfig\":{\"status\":\"unknown_value\",\"lastUpdated\":1787293426658}}"
        let data = jsonString.data(using: .utf8)

        runtimeConfig.handleSRConfigResponse(data: data)

        XCTAssertEqual(runtimeConfig.srServerConfig, .srDefault)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 1787293426658)
    }

    func test_handleSRConfigResponse_staleTimestamp_ignored() {
        let runtimeConfig = RuntimeConfiguration()
        let initialJson = "{\"sessionReplayConfig\":{\"status\":\"enabled\",\"lastUpdated\":2000}}"
        runtimeConfig.handleSRConfigResponse(data: initialJson.data(using: .utf8))
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(runtimeConfig.configurationTimeStamp, 2000)

        // Receive stale response with older timestamp
        let staleJson = "{\"sessionReplayConfig\":{\"status\":\"disabled\",\"lastUpdated\":1000}}"
        runtimeConfig.handleSRConfigResponse(data: staleJson.data(using: .utf8))

        // State should remain enabled and not disabled
        XCTAssertEqual(runtimeConfig.srServerConfig, .enabled)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: configSessionReplayStateKey), RuntimeConfiguration.SessionReplayServerConfig.enabled.rawValue)
        XCTAssertEqual(UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64, 2000)
    }

    // MARK: - setSRConfigHeader Tests

    func test_setSRConfigHeader_srStatusNotIntegrated_headerNotSet() {
        let runtimeConfig = RuntimeConfiguration()
        runtimeConfig.update { state in
            state.configurationTimeStamp = 1787293426658
        }

        var request = URLRequest(url: URL(string: "http://localhost")!)
        runtimeConfig.setSRConfigHeader(&request, srStatus: "3")

        XCTAssertNil(request.value(forHTTPHeaderField: "x-instana-ios-config-time"))
    }

    func test_setSRConfigHeader_srStatusIntegrated_setsTimestampHeader() {
        let runtimeConfig = RuntimeConfiguration()
        runtimeConfig.update { state in
            state.configurationTimeStamp = 1787293426658
        }

        var request = URLRequest(url: URL(string: "http://localhost")!)
        runtimeConfig.setSRConfigHeader(&request, srStatus: "1")

        XCTAssertEqual(request.value(forHTTPHeaderField: "x-instana-ios-config-time"), "1787293426658")
    }

    func test_setSRConfigHeader_nilSrStatus_setsTimestampHeader() {
        let runtimeConfig = RuntimeConfiguration()
        runtimeConfig.update { state in
            state.configurationTimeStamp = 5555
        }

        var request = URLRequest(url: URL(string: "http://localhost")!)
        runtimeConfig.setSRConfigHeader(&request, srStatus: nil)

        XCTAssertEqual(request.value(forHTTPHeaderField: "x-instana-ios-config-time"), "5555")
    }

    func test_setSRConfigHeader_defaultTimestamp_setsZeroHeader() {
        let runtimeConfig = RuntimeConfiguration()

        var request = URLRequest(url: URL(string: "http://localhost")!)
        runtimeConfig.setSRConfigHeader(&request, srStatus: "0")

        XCTAssertEqual(request.value(forHTTPHeaderField: "x-instana-ios-config-time"), "0")
    }

    // MARK: - Thread Safety Tests

    func test_concurrentUpdatesAndReads_threadSafety() {
        let runtimeConfig = RuntimeConfiguration()
        let iterations = 100
        let dispatchGroup = DispatchGroup()

        for i in 1...iterations {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                runtimeConfig.update { state in
                    state.srServerConfig = (i % 2 == 0) ? .enabled : .disabled
                    state.configurationTimeStamp = Int64(i)
                }
                _ = runtimeConfig.srServerConfig
                _ = runtimeConfig.configurationTimeStamp
                _ = runtimeConfig.configState
                dispatchGroup.leave()
            }
        }

        let result = dispatchGroup.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success)
        XCTAssertGreaterThan(runtimeConfig.configurationTimeStamp, 0)
    }
}
