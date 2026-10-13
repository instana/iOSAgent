//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
@_spi(Internal) import InstanaAgent

/// Detects frequent app force kills.
/// Simple logic: If app cold start counter 3+ times within 2 minutes = force kill loop.
/// Should be called once during Session Replay initialization.
class FrequentRestart {

    static let keyRestartTimestamps = "instana_app_restart_timestamps"
    static let maxForceKills = 3
    static let timeWindowMinutes: Int64 = 2

    /// Call this method on app startup to check for force kill pattern.
    static func checkForForceKill() {
        let currentTime = Date().millisecondsSince1970

        var timestamps = loadTimestamps()
        timestamps.append(currentTime)
        saveTimestamps(timestamps)

        checkForForceKillLoop(currentTime: currentTime)
    }

    private static func checkForForceKillLoop(currentTime: Int64) {
        let timestamps = loadTimestamps().sorted()

        guard timestamps.count >= maxForceKills else {
            return
        }

        let cutoffMillis = timeWindowMinutes * 60 * 1000

        // Retain timestamps only within last 2 minutes
        let recent = timestamps.filter { (currentTime - Int64($0)) <= cutoffMillis }

        if recent.count < timestamps.count {
            saveTimestamps(recent)
        }

        if recent.count >= maxForceKills {
            let beacon = UserEventBeacon(timestamp: Instana.Types.Milliseconds(currentTime),
                                         eventType: UserActionEnum.frustrationSignal.rawValue,
                                         eventValue: FrustrationSignalValueEnum.frequentAppKillRestart.rawValue,
                                         eventValueKey: userActionKey_frustrationSignal)
            Instana.reportUserEventDetails(beacon: beacon)
            UserDefaults.standard.removeObject(forKey: keyRestartTimestamps)
        }
    }

    private static func loadTimestamps() -> [Int64] {
        guard let raw = UserDefaults.standard.string(forKey: keyRestartTimestamps), !raw.isEmpty else {
            return []
        }
        return raw.split(separator: ",").compactMap { Int64($0) }
    }

    private static func saveTimestamps(_ timestamps: [Int64]) {
        let joined = timestamps.map { "\($0)" }.joined(separator: ",")
        UserDefaults.standard.set(joined, forKey: keyRestartTimestamps)
    }
}
