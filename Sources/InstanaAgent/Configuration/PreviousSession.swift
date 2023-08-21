//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

struct PreviousSession: Codable {
    var id: UUID
    var startTime: Date
    var viewName: String
    var carrier: String?
    var connectionType: String?
    var userID: String?
    var userEmail: String?
    var userName: String?

    init(id: UUID, startTime: Date, viewName: String,
         carrier: String?, connectionType: String?,
         userID: String?, userEmail: String?, userName: String?) {
        self.id = id
        self.startTime = startTime
        self.viewName = viewName
        self.carrier = carrier
        self.connectionType = connectionType
        self.userID = userID
        self.userEmail = userEmail
        self.userName = userName
    }

    static func cleanupPreviousSessionUserDefaults() {
        UserDefaults.standard.removeObject(forKey: sessionIDKey)
        UserDefaults.standard.removeObject(forKey: sessionStartTimeKey)
        UserDefaults.standard.removeObject(forKey: viewNameKey)
        UserDefaults.standard.removeObject(forKey: carrierKey)
        UserDefaults.standard.removeObject(forKey: connectionTypeKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
    }

    ///
    /// Read in and parse saved previous session id, session start time etc.
    ///
    static func readInPreviousSessionData() -> PreviousSession? {
        defer {
            cleanupPreviousSessionUserDefaults()
        }

        guard let sidStr = UserDefaults.standard.string(forKey: sessionIDKey),
            let prevSessionID = UUID(uuidString: sidStr) else { return nil }

        let prevSessionStartTimeInt = UserDefaults.standard.integer(forKey: sessionStartTimeKey)
        if prevSessionStartTimeInt == 0 {
            return nil
        }
        let startTime = Date(timeIntervalSince1970: TimeInterval(prevSessionStartTimeInt))
        if startTime.addingTimeInterval(TimeInterval(maxSecondsToKeepCrashLog)) < Date() || startTime > Date() {
            return nil
        }

        let viewName = UserDefaults.standard.string(forKey: viewNameKey) ?? defaultCrashViewName
        let carrier = UserDefaults.standard.string(forKey: carrierKey)
        let connectionType = UserDefaults.standard.string(forKey: connectionTypeKey)
        let userID = UserDefaults.standard.string(forKey: userIDKey)
        let userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        let userName = UserDefaults.standard.string(forKey: userNameKey)

        return PreviousSession(id: prevSessionID, startTime: startTime, viewName: viewName,
                               carrier: carrier, connectionType: connectionType,
                               userID: userID, userEmail: userEmail, userName: userName)
    }

    static func persistSessionID(sid: UUID) {
        UserDefaults.standard.setValue(sid.uuidString, forKey: sessionIDKey)
        UserDefaults.standard.setValue(Int64(Date().timeIntervalSince1970), forKey: sessionStartTimeKey)
    }

    static func persistUser(id: String, email: String?, name: String?) {
        UserDefaults.standard.set(id, forKey: userIDKey)
        if email != nil {
            UserDefaults.standard.set(email, forKey: userEmailKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userEmailKey)
        }
        if name != nil {
            UserDefaults.standard.set(name, forKey: userNameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userNameKey)
        }
    }

    static func persistView(viewName: String?) {
        if viewName != nil {
            UserDefaults.standard.set(viewName!, forKey: viewNameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: viewNameKey)
        }
    }

    static func isCrashTimeWithinRange(_ time: Date) -> Bool {
        if time.addingTimeInterval(TimeInterval(maxSecondsToKeepCrashLog)) > Date(), time <= Date() {
            return true
        }
        Instana.current?.session.logger.add("Crash time \(Date().description) is beyond range, discarded.", level: .debug)
        return false
    }

    static func isCrashTimeWithinRange(_ time: Instana.Types.Milliseconds) -> Bool {
        // time is time-interval-since-1970 in milliseconds
        let curTime = Date().millisecondsSince1970
        if (curTime - time) < (maxSecondsToKeepCrashLog * 1000), time <= curTime {
            return true
        }
        Instana.current?.session.logger.add("Crash time \(Date().description) is beyond range, discarded.", level: .debug)
        return false
    }
}
