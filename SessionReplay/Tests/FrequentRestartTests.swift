//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class FrequentRestartTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: FrequentRestart.keyRestartTimestamps)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: FrequentRestart.keyRestartTimestamps)
        super.tearDown()
    }

    func test_checkForForceKillLoop_firstRun() throws {
        // When
        FrequentRestart.checkForForceKill()

        // Then
        let raw = UserDefaults.standard.string(forKey: FrequentRestart.keyRestartTimestamps)
        let parsed = raw!.split(separator: ",").compactMap { Int64($0) }
        XCTAssertEqual(parsed.count, 1)
    }

    func test_checkForForceKillLoop_secondRun() throws {
        // Given
        var prevTimes: [Int64] = []
        prevTimes.append(Date().millisecondsSince1970 - 1)
        let joined = prevTimes.map { "\($0)" }.joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: FrequentRestart.keyRestartTimestamps)

        // When
        FrequentRestart.checkForForceKill()

        // Then
        let raw = UserDefaults.standard.string(forKey: FrequentRestart.keyRestartTimestamps)
        let parsed = raw!.split(separator: ",").compactMap { Int64($0) }
        XCTAssertEqual(parsed.count, 2)
    }

    func test_checkForForceKillLoop_tooFrequent() throws {
        // Given
        var prevTimes: [Int64] = []
        for _ in 1 ..< FrequentRestart.maxForceKills {
            prevTimes.append(Date().millisecondsSince1970 - 1)
        }
        let joined = prevTimes.map { "\($0)" }.joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: FrequentRestart.keyRestartTimestamps)

        // When
        FrequentRestart.checkForForceKill()

        // Then
        let raw = UserDefaults.standard.string(forKey: FrequentRestart.keyRestartTimestamps)
        XCTAssertTrue(raw == nil)
    }

    func test_checkForForceKillLoop_oldTimePurge() throws {
        // Given
        var prevTimes: [Int64] = []

        let cutoffMillis = FrequentRestart.timeWindowMinutes * 60 * 1000
        prevTimes.append(Date().millisecondsSince1970 - cutoffMillis - 1)
        prevTimes.append(Date().millisecondsSince1970 - 1)
        let joined = prevTimes.map { "\($0)" }.joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: FrequentRestart.keyRestartTimestamps)

        // When
        FrequentRestart.checkForForceKill()

        // Then
        let raw = UserDefaults.standard.string(forKey: FrequentRestart.keyRestartTimestamps)
        let parsed = raw!.split(separator: ",").compactMap { Int64($0) }
        XCTAssertTrue(parsed.count == 2)
    }
}
