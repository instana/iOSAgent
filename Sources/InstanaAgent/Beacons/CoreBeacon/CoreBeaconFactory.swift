import Foundation

class CoreBeaconFactory {
    private let session: InstanaSession
    private var conf: InstanaConfiguration { session.configuration }
    private var properties: InstanaProperties { session.propertyHandler.properties }

    init(_ session: InstanaSession) {
        self.session = session
    }

    func map(_ beacons: [Beacon]) throws -> [CoreBeacon] {
        return try beacons.map { try map($0) }
    }

    func map(_ beacon: Beacon) throws -> CoreBeacon {
        var cbeacon = CoreBeacon.createDefault(viewName: beacon.viewName,
                                               key: conf.key,
                                               timestamp: beacon.timestamp,
                                               sessionID: beacon.sessionID,
                                               id: beacon.id,
                                               properties: properties)
        switch beacon {
        case let item as HTTPBeacon:
            cbeacon.append(item)
        case let item as ViewChange:
            cbeacon.append(item)
        case let item as AlertBeacon:
            cbeacon.append(item)
        case let item as SessionProfileBeacon:
            cbeacon.append(item)
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
        et = beacon.error?.rawValue
        em = beacon.error?.description
        if beacon.error != nil {
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

    mutating func append(_ beacon: ViewChange) {
        t = .viewChange
    }

    mutating func append(_ beacon: AlertBeacon) {
        t = .alert
        // nothing yet defined
    }

    mutating func append(_ beacon: SessionProfileBeacon) {
        if beacon.state == .start {
            t = .sessionStart // there is no sessionEnd yet
        }
    }

    static func createDefault(viewName: String?,
                              key: String,
                              timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
                              sessionID: UUID = UUID(),
                              id: UUID = UUID(),
                              connectionType: NetworkUtility.ConnectionType = InstanaSystemUtils.networkUtility.connectionType,
                              properties: InstanaProperties) -> CoreBeacon {
        CoreBeacon(v: viewName,
                   k: key,
                   ti: String(timestamp),
                   sid: sessionID.uuidString,
                   bid: id.uuidString,
                   buid: InstanaSystemUtils.applicationBundleIdentifier,
                   m: properties.metaData,
                   ui: properties.user?.id,
                   un: properties.user?.name,
                   ue: properties.user?.email,
                   ul: Locale.current.languageCode,
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
        let kvPairs = lines.reduce([String: Any]()) { result, line -> [String: Any] in
            let components = line.components(separatedBy: "\t")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            return newResult
        }

        let jsonData = try JSONSerialization.data(withJSONObject: kvPairs, options: .prettyPrinted)
        let beacon = try JSONDecoder().decode(CoreBeacon.self, from: jsonData)
        return beacon
    }
}
