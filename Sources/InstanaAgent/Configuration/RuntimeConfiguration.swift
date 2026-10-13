//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

public class RuntimeConfiguration {
    // Session Replay server side configuration
    public enum SessionReplayServerConfig: Int {
        case srDefault = 0
        case enabled = 1
        case disabled = 2
    }

    // MARK: - Value snapshot (guarded by lock as a whole)

    struct ConfigState {
        var srServerConfig: SessionReplayServerConfig = {
            let raw = UserDefaults.standard.integer(forKey: configSessionReplayStateKey)
            return SessionReplayServerConfig(rawValue: raw) ?? .srDefault
        }()

        var configurationTimeStamp: Instana.Types.Milliseconds = {
            let stored = UserDefaults.standard.object(forKey: configServerSideTimeStampKey) as? Int64
            return stored ?? 0
        }()
    }

    // MARK: - Thread-safe access

    private let lock = NSLock()
    private var _configState = ConfigState()

    /// Read a consistent snapshot of the entire configuration atomically.
    var configState: ConfigState {
        lock.atomic { _configState }
    }

    /// Replace the entire configuration atomically.
    /// Posts `.runtimeConfigurationUpdated` on NotificationCenter.default when configurationTimeStamp changes.
    func update(_ block: (inout ConfigState) -> Void) {
        let shouldNotify: Bool = lock.atomic {
            let previousTimestamp = _configState.configurationTimeStamp
            let previousSrServerConfig = _configState.srServerConfig
            block(&_configState)
            let timestampUpdated = _configState.configurationTimeStamp > previousTimestamp
            if timestampUpdated {
                UserDefaults.standard.set(_configState.srServerConfig.rawValue, forKey: configSessionReplayStateKey)
                UserDefaults.standard.set(_configState.configurationTimeStamp, forKey: configServerSideTimeStampKey)
            } else {
                // restore server config in case server inadvertently changed the config when timestamp was not updated
                _configState.srServerConfig = previousSrServerConfig
            }
            return timestampUpdated
        }
        if shouldNotify {
            NotificationCenter.default.post(name: .runtimeConfigurationUpdated, object: self)
        }
    }

    // MARK: - Convenience read-only accessors

    public var srServerConfig: SessionReplayServerConfig { configState.srServerConfig }

    public var configurationTimeStamp: Instana.Types.Milliseconds { configState.configurationTimeStamp }

    // MARK: - Init

    init() {}

    // MARK: - SessionReplay Config response handling

    /// Parses a status-200 Session Replay config response body and persists it to RuntimeConfiguration.
    /// Expected JSON: {"sessionReplayConfig": {"status": "default", "lastUpdated": 1787252919816}}
    func handleSRConfigResponse(data: Data?) {
        guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Instana.current?.session.logger.add("Error converting Server side configuration to JSON", level: .warning)
            return
        }

        // Extract the nested "sessionReplayConfig" object (case-insensitive key lookup)
        let lowercasedTopLevel = Dictionary(uniqueKeysWithValues: json.map { ($0.key.lowercased(), $0.value) })
        guard let innerObj = lowercasedTopLevel["sessionreplayconfig"] as? [String: Any] else {
            Instana.current?.session.logger.add("Missing sessionReplayConfig key in server config response", level: .warning)
            return
        }

        // Convert inner keys to lowercase for case-insensitive field access
        let lowercasedJson = Dictionary(uniqueKeysWithValues: innerObj.map { ($0.key.lowercased(), $0.value) })
        update { state in
            if let statusStr = lowercasedJson["status"] as? String {
                switch statusStr.lowercased() {
                case "enabled": state.srServerConfig = .enabled
                case "disabled": state.srServerConfig = .disabled
                default: state.srServerConfig = .srDefault
                }
            }
            if let lastUpdated = lowercasedJson["lastupdated"] as? Int64 {
                state.configurationTimeStamp = lastUpdated
            }
        }
    }

    // set last updated server side Session Replay configuration timestamp header
    func setSRConfigHeader(_ request: inout URLRequest, srStatus: String?) {
        // skip if session replay is not integrated with the app
        guard srStatus != "3" else {
            return
        }
        request.setValue(String(configState.configurationTimeStamp), forHTTPHeaderField: "x-instana-ios-config-time")
    }
}
