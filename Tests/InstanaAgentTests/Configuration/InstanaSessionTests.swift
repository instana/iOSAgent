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

    func test_usiNotAllowed() {
        // Given
        let propertyHandler = InstanaPropertyHandler()

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: usiTrackingNotAllowed)
        let sut = InstanaSession(configuration: configUsi, propertyHandler: propertyHandler, collectionEnabled: true)

        // Then
        AssertTrue(sut.collectionEnabled)
        XCTAssertNil(sut.usi)
    }

    func test_usiExpired() {
        // Given
        let propertyHandler = InstanaPropertyHandler()

        // When
        let configUsi = InstanaConfiguration(reportingURL: .random, key: "KEY", httpCaptureConfig: .automatic,
                                             enableCrashReporting: false, slowSendInterval: 0.0,
                                             usiRefreshTimeIntervalInHrs: (1.0 / 3600.0))
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
    }
}
