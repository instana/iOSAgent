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
        var cbeacon = CoreBeacon.createDefault(viewName: beacon.viewName, key: conf.key, timestamp: beacon.timestamp, sid: session.id, id: beacon.id)
        cbeacon.append(properties)
        switch beacon {
        case let item as HTTPBeacon:
            cbeacon.append(item)
        case let item as ViewChange:
            cbeacon.append(item)
        case let item as AlertBeacon:
            cbeacon.append(item)
        case let item as SessionProfileBeacon:
            cbeacon.append(item)
        case let item as CustomBeacon:
            cbeacon.append(item, properties: properties)
        default:
            let message = "Beacon <-> CoreBeacon mapping for beacon \(beacon) not defined"
            debugAssertFailure(message)
            session.logger.add(message, level: .error)
            throw InstanaError(code: .unknownType, description: message)
        }
        return cbeacon
    }
}

extension CoreBeacon {
    mutating func append(_ properties: InstanaProperties) {
        v = v ?? properties.viewNameForCurrentAppState
        ui = properties.user?.id
        un = properties.user?.name
        ue = properties.user?.email
        m = properties.metaData
    }

    mutating func append(_ beacon: HTTPBeacon) {
        t = .httpRequest
        bt = beacon.backendTracingID
        hu = beacon.url.absoluteString
        hp = beacon.path
        hs = String(beacon.responseCode)
        hm = beacon.method
        d = String(beacon.duration)
        if let error = beacon.error {
            add(error: error)
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

    mutating func append(_ beacon: CustomBeacon, properties: InstanaProperties) {
        t = .custom
        let useCurrentVisibleViewName = beacon.viewName == CustomBeaconDefaultViewNameID
        v = useCurrentVisibleViewName ? properties.viewNameForCurrentAppState : beacon.viewName
        cen = beacon.name
        m = beacon.meta
        if let error = beacon.error {
            add(error: error)
        }
        if let duration = beacon.duration {
            d = String(duration)
        }
        if let tracingID = beacon.backendTracingID {
            bt = tracingID
        }
    }

    private mutating func add(error: Error) {
        et = "\(type(of: error))"
        if let httpError = error as? HTTPError {
            em = "\(httpError.rawValue): \(httpError.errorDescription)"
        } else {
            em = "\(error)"
        }
        ec = String(1)
    }

    static func createDefault(viewName: String?,
                              key: String,
                              timestamp: Instana.Types.Milliseconds,
                              sid: UUID,
                              id: UUID,
                              connection: NetworkUtility.ConnectionType = InstanaSystemUtils.networkUtility.connectionType) -> CoreBeacon {
        CoreBeacon(v: viewName,
                   k: key,
                   ti: String(timestamp),
                   sid: sid.uuidString,
                   bid: id.uuidString,
                   bi: InstanaSystemUtils.applicationBundleIdentifier,
                   ul: Locale.current.languageCode,
                   ab: InstanaSystemUtils.applicationBuildNumber,
                   av: InstanaSystemUtils.applicationVersion,
                   p: InstanaSystemUtils.systemName,
                   osn: InstanaSystemUtils.systemName,
                   osv: InstanaSystemUtils.systemVersion,
                   dmo: InstanaSystemUtils.deviceModel,
                   agv: InstanaSystemUtils.agentVersion,
                   ro: String(InstanaSystemUtils.isDeviceJailbroken),
                   vw: String(Int(InstanaSystemUtils.screenSize.width)),
                   vh: String(Int(InstanaSystemUtils.screenSize.height)),
                   cn: connection.cellular.carrierName,
                   ct: connection.description)
    }

    static func create(from httpBody: String) throws -> CoreBeacon {
        var metaPairs = [String: String]()
        let lines = httpBody.components(separatedBy: "\n")
        var kvPairs = lines.reduce([String: Any]()) { result, line -> [String: Any] in
            let components = line.components(separatedBy: "\t")
            guard let key = components.first, let value = components.last else { return result }
            var newResult = result
            newResult[key] = value
            if key.hasPrefix("m_") {
                let newKey = key.replacingOccurrences(of: "m_", with: "")
                metaPairs[newKey] = value
            }
            return newResult
        }
        if metaPairs.count > 0 {
            kvPairs["m"] = metaPairs
        }
        let jsonData = try JSONSerialization.data(withJSONObject: kvPairs, options: .prettyPrinted)
        let beacon = try JSONDecoder().decode(CoreBeacon.self, from: jsonData)
        return beacon
    }
}
