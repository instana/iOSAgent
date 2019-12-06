
import Foundation

class CoreBeaconFactory {
    private let configuration: InstanaConfiguration

    init(_ configuration: InstanaConfiguration) {
        self.configuration = configuration
    }

    func map(_ events: [Event]) throws -> [CoreBeacon] {
        return try events.map { try map($0)}
    }

    func map(_ event: Event) throws -> CoreBeacon {
        var beacon = CoreBeacon.createDefault(key: configuration.key, timestamp: event.timestamp, sessionId: event.sessionId, id: event.id)
        switch event {
        case let e as HTTPEvent:
            beacon.append(e)
        case let e as AlertEvent:
            beacon.append(e)
        case let e as CustomEvent:
            beacon.append(e)
        case let e as SessionProfileEvent:
            beacon.append(e)
        default:
            let message = "Event <-> Beacon mapping for event \(event) not defined"
            debugAssertFailure(message)
            throw InstanaError(code: .unknownType, description: message)
        }
        return beacon
    }
}

extension CoreBeacon {

    mutating func append(_ event: HTTPEvent) {
        t = .httpRequest
        hu = event.url.absoluteString
        hp = event.path
        hs = String(event.responseCode)
        hm = event.method
        trs = String(event.responseSize)
        d = String(event.duration)
    }

    mutating func append(_ event: AlertEvent) {
        t = .custom // not yet defined
    }

    mutating func append(_ event: CustomEvent) {
        t = .custom
    }

    mutating func append(_ event: SessionProfileEvent) {
        if event.state == .start {
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
               cn: InstanaSystemUtils.carrierName,
               ct: InstanaSystemUtils.connectionTypeDescription)
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
