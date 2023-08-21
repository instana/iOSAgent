//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class InstanaSession {
    /// The current Instana configuration
    @Atomic var configuration: InstanaConfiguration

    /// Instana global property handler that will attach the custom properties to each monitored event. (beacon)
    /// Those values can be changed any time by the Instana agent consumer (i.e. iOS app).
    /// This class is thread-safe
    @Atomic var propertyHandler: InstanaPropertyHandler

    /// The Session ID created on each app launch
    let id: UUID

    /// A unique ID that represents the device
    private var userSessionID: UUID?
    var usiStartTime: TimeInterval?
    var usi: UUID? {
        if !isSessionValid() {
            (userSessionID, usiStartTime) = InstanaSession.usiNew(configuration)
        }
        return userSessionID
    }

    /// Session information for previous app launch
    /// so as to assist metric kit payload analyse
    var previousSession: PreviousSession?

    /// A debugging console logger using levels
    let logger = InstanaLogger()

    /// Collecting and reporting can be disabled or enabled at any time
    @Atomic var collectionEnabled: Bool

    init(configuration: InstanaConfiguration, propertyHandler: InstanaPropertyHandler, sessionID: UUID = UUID(), collectionEnabled: Bool) {
        self.configuration = configuration
        self.propertyHandler = propertyHandler
        self.collectionEnabled = collectionEnabled

        previousSession = PreviousSession.readInPreviousSessionData()
        id = sessionID
        (userSessionID, usiStartTime) = InstanaSession.usiRetrieve(configuration)
        PreviousSession.persistSessionID(sid: sessionID)
    }

    private func isSessionValid() -> Bool {
        // Do now allow user_session_id tracking
        if configuration.usiRefreshTimeIntervalInHrs == usiTrackingNotAllowed {
            return true
        }

        // user_session_id never expires
        if configuration.usiRefreshTimeIntervalInHrs < 0 {
            return userSessionID != nil
        }

        guard let usiStartTime = usiStartTime else { return false }
        let usiTimeElapse = Date().timeIntervalSince1970 - usiStartTime
        if usiTimeElapse > Double(configuration.usiRefreshTimeIntervalInHrs) * 3600.0 {
            return false
        }
        return true
    }

    private static func usiRetrieve(_ config: InstanaConfiguration) -> (UUID?, TimeInterval?) {
        if config.usiRefreshTimeIntervalInHrs == usiTrackingNotAllowed {
            UserDefaults.standard.removeObject(forKey: userSessionIDKey)
            UserDefaults.standard.removeObject(forKey: usi_startTimeKey)
            return (nil, nil)
        }

        var usiActive: UUID?
        var startTime: TimeInterval?

        let idStr = UserDefaults.standard.string(forKey: userSessionIDKey)
        if idStr != nil {
            usiActive = UUID(uuidString: idStr!)
            if usiActive == nil {
                UserDefaults.standard.removeObject(forKey: userSessionIDKey)
            } else {
                let startTimeRead = UserDefaults.standard.double(forKey: usi_startTimeKey)
                let now = Date().timeIntervalSince1970
                if startTimeRead > 0, startTimeRead <= now {
                    startTime = startTimeRead
                } else {
                    usiActive = nil
                }
            }
        }

        if usiActive == nil {
            return usiNew(config)
        }
        return (usiActive!, startTime!)
    }

    private static func usiNew(_ config: InstanaConfiguration) -> (UUID?, TimeInterval?) {
        if config.usiRefreshTimeIntervalInHrs == usiTrackingNotAllowed {
            UserDefaults.standard.removeObject(forKey: userSessionIDKey)
            UserDefaults.standard.removeObject(forKey: usi_startTimeKey)
            return (nil, nil)
        }

        let usiActive = UUID()
        UserDefaults.standard.setValue(usiActive.uuidString, forKey: userSessionIDKey)

        var startTime: TimeInterval?
        if config.usiRefreshTimeIntervalInHrs > 0 {
            startTime = Date().timeIntervalSince1970
            UserDefaults.standard.setValue(startTime, forKey: usi_startTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: usi_startTimeKey)
        }
        return (usiActive, startTime)
    }
}
