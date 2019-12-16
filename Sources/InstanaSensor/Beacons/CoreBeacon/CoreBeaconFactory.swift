
import Foundation

class CoreBeaconFactory {
    private let environment: InstanaEnvironment
    private var conf: InstanaConfiguration { environment.configuration }
    private var properties: InstanaProperties { environment.propertyHandler.properties }

    init(_ environment: InstanaEnvironment) {
        self.environment = environment
    }

    func map(_ beacons: [Beacon]) throws -> [CoreBeacon] {
        return try beacons.map { try map($0)}
    }

    func map(_ beacon: Beacon) throws -> CoreBeacon {
        var cbeacon = CoreBeacon.createDefault(key: conf.key, timestamp: beacon.timestamp, sessionID: beacon.sessionID, id: beacon.id, properties: properties)
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
        bt = beacon.backendTracingID
        hu = beacon.url.absoluteString
        hp = beacon.path
        hs = String(beacon.responseCode)
        hm = beacon.method
        d = String(beacon.duration)

        if 400...599 ~= beacon.responseCode {
            ec = String(1)
        }

        if let responseSize = beacon.responseSize {
            if let headerSize = responseSize.headerBytes, let bodySize = responseSize.bodyBytes {
                trs = String(headerSize + bodySize)
            }
            if let bodySize = responseSize.bodyBytes {
                ebs = String(bodySize)
            }
            if let bodyBytesAfterDecoding = responseSize.bodyBytesAfterDecoding {
                dbs = String(bodyBytesAfterDecoding)
            }
        }
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
                              sessionID: UUID = UUID(),
                              id: UUID = UUID(),
                              connectionType: NetworkUtility.ConnectionType = InstanaSystemUtils.networkUtility.connectionType,
                              properties: InstanaProperties) -> CoreBeacon {
        CoreBeacon(v: properties.view,
                   k: key,
                   ti: String(timestamp),
                   sid: sessionID.uuidString,
                   bid: id.uuidString,
                   buid: InstanaSystemUtils.applicationBundleIdentifier,
                   m: properties.metaData,
                   ui: properties.user?.id,
                   un: properties.user?.name,
                   ue: properties.user?.email,
                   ul: Locale.current.languageCode ?? "na",
                   ab: InstanaSystemUtils.applicationBuildNumber,
                   av: InstanaSystemUtils.applicationVersion,
                   osn: InstanaSystemUtils.systemName,
                   osv: InstanaSystemUtils.systemVersion,
                   dmo: InstanaSystemUtils.deviceModel,
                   ro: String(InstanaSystemUtils.isDeviceJailbroken),
                   vw: String(Int(InstanaSystemUtils.screenSize.width)),
                   vh: String(Int(InstanaSystemUtils.screenSize.height)),
                   cn: connectionType.cellular.carrierName,
                   ct: connectionType.description)
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
