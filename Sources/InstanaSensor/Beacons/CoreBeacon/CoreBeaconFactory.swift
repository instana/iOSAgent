
import Foundation

class CoreBeaconFactory {
    private let configuration: InstanaConfiguration

    init(_ configuration: InstanaConfiguration) {
        self.configuration = configuration
    }

    func map(_ beacons: [Beacon]) throws -> [CoreBeacon] {
        return try beacons.map { try map($0)}
    }

    func map(_ beacon: Beacon) throws -> CoreBeacon {
        var cbeacon = CoreBeacon.createDefault(key: configuration.key, timestamp: beacon.timestamp, sessionId: beacon.sessionId, id: beacon.id)
        switch beacon {
        case let b as HTTPBeacon:
            cbeacon.append(b)
        case let b as AlertBeacon:
            cbeacon.append(b)
        case let b as CustomBeacon:
            cbeacon.append(b)
        case let b as SessionProfileBeacon:
            cbeacon.append(b)
        default:
            let message = "Beacon <-> CoreBeacon mapping for beacon \(beacon) not defined"
            debugAssertFailure(message)
            throw InstanaError(code: .unknownType, description: message)
        }
        return cbeacon
    }
}

extension CoreBeacon {

    mutating func append(_ beacon: HTTPBeacon) {
        t = .httpRequest
        hu = beacon.url.absoluteString
        hp = beacon.path
        hs = String(beacon.responseCode)
        hm = beacon.method
        trs = String(beacon.responseSize)
        d = String(beacon.duration)
    }

    mutating func append(_ beacon: AlertBeacon) {
        t = .custom // not yet defined
    }

    mutating func append(_ beacon: CustomBeacon) {
        t = .custom
    }

    mutating func append(_ beacon: SessionProfileBeacon) {
        if beacon.state == .start {
            t = .sessionStart  // there is no sessionEnd yet
        }
    }

    static func createDefault(key: String,
                              timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
                              sessionId: String = UUID().uuidString,
                              id: String = UUID().uuidString) -> CoreBeacon {
        CoreBeacon(v: InstanaSystemUtils.viewControllersHierarchy(),
               k: key,
               ti: String(timestamp),
               sid: sessionId,
               bid: id,
               buid: InstanaSystemUtils.applicationBundleIdentifier,
               ul: Locale.current.languageCode ?? "na",
               ab: InstanaSystemUtils.applicationBuildNumber,
               av: InstanaSystemUtils.applicationVersion,
               osn: InstanaSystemUtils.systemName,
               osv: InstanaSystemUtils.systemVersion,
               dmo: InstanaSystemUtils.deviceModel,
               ro: String(InstanaSystemUtils.isDeviceJailbroken),
               vw: String(Int(InstanaSystemUtils.screenSize.width)),
               vh: String(Int(InstanaSystemUtils.screenSize.height)),
               cn: InstanaSystemUtils.networkMonitor.connectionType.cellular.carrierName,
               ct: InstanaSystemUtils.networkMonitor.connectionType.description)
    }

    static func create(from httpBody: String) throws -> CoreBeacon {
        let lines = httpBody.components(separatedBy: "\n")
        let kvPairs = lines.reduce([String: Any](), {result, line -> [String: Any] in
            let components = line.components(separatedBy: "\t")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            return newResult
        })

        let jsonData = try JSONSerialization.data(withJSONObject: kvPairs, options: .prettyPrinted)
        let beacon = try JSONDecoder().decode(CoreBeacon.self, from: jsonData)
        return beacon
    }
}
