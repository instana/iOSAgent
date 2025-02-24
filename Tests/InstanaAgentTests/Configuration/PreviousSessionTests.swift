//
//  Copyright © 2025 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class PreviousSessionTests: InstanaTestCase {

    func test_readInPreviousSessionData_sessionStartTime0() {
        // Given
        PreviousSession.persistSessionID(sid: UUID())
        UserDefaults.standard.removeObject(forKey: sessionStartTimeKey)

        // When
        let prevSession = PreviousSession.readInPreviousSessionData()

        // Then
        AssertTrue(prevSession == nil)
    }

    func test_readInPreviousSessionData_sessionStartTime_invalid() {
        // Given
        PreviousSession.persistSessionID(sid: UUID())
        UserDefaults.standard.setValue(Date.distantFuture.timeIntervalSince1970, forKey: sessionStartTimeKey)

        // When
        let prevSession = PreviousSession.readInPreviousSessionData()

        // Then
        AssertTrue(prevSession == nil)
    }

    func test_readInPreviousSessionData_sessionStartTime_crashTooOld() {
        // Given
        PreviousSession.persistSessionID(sid: UUID())
        UserDefaults.standard.setValue(Int(Date().timeIntervalSince1970) - maxSecondsToKeepCrashLog - 10,
                                       forKey: sessionStartTimeKey)

        // When
        let prevSession = PreviousSession.readInPreviousSessionData()

        // Then
        AssertTrue(prevSession == nil)
    }

    func test_isCrashTimeWithinRange() {
        // When
        let isWithinRange = PreviousSession.isCrashTimeWithinRange(Date.distantFuture)

        // Then
        AssertFalse(isWithinRange)
    }
}
