//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaSessionTests: InstanaTestCase {

    func test_defaultInit() {
        // Given
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = InstanaSession(configuration: config, propertyHandler: propertyHandler, collectionEnabled: true)

        // Then
        AssertTrue(!sut.id.uuidString.isEmpty)
        AssertEqualAndNotNil(sut.propertyHandler, propertyHandler)
        AssertEqualAndNotNil(sut.configuration, config)
        AssertTrue(sut.collectionEnabled)
    }

    func test_usiRetrieve_default_firstTimeAppRun() {
        // Given
        let propertyHandler = InstanaPropertyHandler()
        UserDefaults.standard.removeObject(forKey: userSessionIDKey)
        UserDefaults.standard.removeObject(forKey: usi_startTimeKey)

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY1", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: defaultUsiRefreshTimeIntervalInHrs,
                                             rateLimits: RateLimits.DEFAULT_LIMITS,
                                             perfConfig: nil,
                                             hybridAgentId: nil,
                                             hybridAgentVersion: nil)
        let sut = InstanaSession(configuration: configUsi, propertyHandler: propertyHandler, collectionEnabled: true)

        // Then
        XCTAssertNotNil(sut.usi)
        XCTAssertNil(sut.usiStartTime)
        XCTAssertNotNil(UserDefaults.standard.object(forKey: userSessionIDKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: usi_startTimeKey))
    }

    func test_usiRetrieve_default_secondTimeAppRun() {
        // Given
        let propertyHandler = InstanaPropertyHandler()
        let usiTestValue = UUID()
        UserDefaults.standard.setValue(usiTestValue.uuidString, forKey: userSessionIDKey)
        UserDefaults.standard.removeObject(forKey: usi_startTimeKey)

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY2", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: defaultUsiRefreshTimeIntervalInHrs,
                                             rateLimits: RateLimits.DEFAULT_LIMITS,
                                             perfConfig: nil,
                                             hybridAgentId: nil,
                                             hybridAgentVersion: nil)
        let sut = InstanaSession(configuration: configUsi, propertyHandler: propertyHandler, collectionEnabled: true)

        // Then
        AssertTrue(sut.usi == usiTestValue)
        XCTAssertNil(sut.usiStartTime)
        XCTAssertNotNil(UserDefaults.standard.object(forKey: userSessionIDKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: usi_startTimeKey))
    }

    func test_usiNotAllowed() {
        // Given
        let propertyHandler = InstanaPropertyHandler()
        let usiTestValue = UUID()
        UserDefaults.standard.setValue(usiTestValue.uuidString, forKey: userSessionIDKey)
        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: usi_startTimeKey)

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: usiTrackingNotAllowed,
                                             rateLimits: RateLimits.DEFAULT_LIMITS,
                                             perfConfig: nil,
                                             hybridAgentId: nil,
                                             hybridAgentVersion: nil)
        let sut = InstanaSession(configuration: configUsi, propertyHandler: propertyHandler, collectionEnabled: true)

        // Then
        AssertTrue(sut.collectionEnabled)
        XCTAssertNil(sut.usi)
        XCTAssertNil(sut.usiStartTime)
        XCTAssertNil(UserDefaults.standard.object(forKey: userSessionIDKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: usi_startTimeKey))
    }

    func test_usiRetrieve_usiRefreshTimeIntervalInHrs_positiveNumber() {
        // Given
        let id = UUID()
        UserDefaults.standard.setValue(id.uuidString, forKey: userSessionIDKey)
        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: usi_startTimeKey)
        config.usiRefreshTimeIntervalInHrs = 12.0

        // When
        let sut = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(), collectionEnabled: true)

        // Then
        AssertEqualAndNotNil(sut.usi, id)
    }

    func test_usiRetrieve_invalid_id_saved() {
        // Given
        let invalidId = "some-invalid-id"
        UserDefaults.standard.setValue(invalidId, forKey: userSessionIDKey)
        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: usi_startTimeKey)
        config.usiRefreshTimeIntervalInHrs = 12.0

        // When
        let sut = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(), collectionEnabled: true)

        // Then
        XCTAssertFalse(sut.usi?.uuidString == invalidId)
    }

    func test_usiNew_usiRefreshTimeIntervalInHrs_positiveNumber() {
        // Given
        UserDefaults.standard.removeObject(forKey: userSessionIDKey)
        UserDefaults.standard.removeObject(forKey: usi_startTimeKey)
        config.usiRefreshTimeIntervalInHrs = 24.0

        // When
        let sut = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(), collectionEnabled: true)

        // Then
        XCTAssertNotNil(sut.usi)
        XCTAssertNotNil(sut.usiStartTime)
        XCTAssertNotNil(UserDefaults.standard.object(forKey: userSessionIDKey))
        XCTAssertNotNil(UserDefaults.standard.object(forKey: usi_startTimeKey))
    }

    func test_usiExpired() {
        // Given
        let propertyHandler = InstanaPropertyHandler()

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: (1.0 / 3600.0),
                                             rateLimits: RateLimits.DEFAULT_LIMITS,
                                             perfConfig: nil,
                                             hybridAgentId: nil,
                                             hybridAgentVersion: nil)
        let sut = InstanaSession(configuration: configUsi, propertyHandler: propertyHandler, collectionEnabled: true)
        let oldUsi = sut.usi?.uuidString

        // Then
        wait(0.5)
        let usiNotExpired = sut.usi?.uuidString
        XCTAssertEqual(oldUsi, usiNotExpired)

        wait(1.0)
        let usi = sut.usi
        let usiExpiredAndNew = usi?.uuidString

        // Then
        XCTAssertNotEqual(oldUsi, usiExpiredAndNew)
        XCTAssertNotNil(sut.usiStartTime)
        XCTAssertNotNil(UserDefaults.standard.object(forKey: userSessionIDKey))
        XCTAssertNotNil(UserDefaults.standard.object(forKey: usi_startTimeKey))
    }
}
