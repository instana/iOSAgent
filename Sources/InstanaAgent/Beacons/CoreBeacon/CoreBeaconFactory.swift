//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class CoreBeaconFactory {
    private let session: InstanaSession
    private var conf: InstanaConfiguration { session.configuration }
    private var properties: InstanaProperties { session.propertyHandler.properties }
    internal var mobileFeatures: String? {
        var array: [String] = []
        if conf.monitorTypes.contains(.crash) {
            array.append(mobileFeatureCrash)
        }
        if conf.monitorTypes.contains(.memoryWarning) {
            array.append(mobileFeaturePerformanceLowMemory)
        }
        if conf.anrThreshold != nil, conf.monitorTypes.contains(
            .alertApplicationNotResponding(threshold: conf.anrThreshold!)) {
            array.append(mobileFeaturePerformanceANR)
        }
        if session.autoCaptureScreenNames {
            array.append(mobileFeatureAutoScreenNameCapture)
        }
        if session.dropBeaconReporting {
            array.append(mobileFeatureDropBeaconReporting)
        }
        if conf.enableW3CHeaders == true {
            array.append(mobileFeatureEnableW3CHeaders)
        }
        return array.isEmpty ? nil : array.joined(separator: ",")
    }

    init(_ session: InstanaSession) {
        self.session = session
    }

    func map(_ beacons: [Beacon]) throws -> [CoreBeacon] {
        return try beacons.map { try map($0) }
    }

    func map(_ beacon: Beacon) throws -> CoreBeacon {
        var cbeacon = CoreBeacon.createDefault(viewName: beacon.viewName, key: conf.key,
                                               timestamp: beacon.timestamp,
                                               sid: session.id, usi: session.usi,
                                               id: beacon.id, mobileFeatures: mobileFeatures,
                                               trustDeviceTiming: conf.trustDeviceTiming,
                                               hybridAgentId: conf.hybridAgentId,
                                               hybridAgentVersion: conf.hybridAgentVersion,
                                               enableAppStateDetection: conf.enableAppStateDetection)
        cbeacon.append(properties)
        switch beacon {
        case let item as HTTPBeacon:
            cbeacon.append(item)
        case let item as ViewChange:
            cbeacon.append(item)
        case let item as DroppedBeacons:
            cbeacon.append(item)
        case let item as PerformanceBeacon:
            cbeacon.append(item)
        case let item as DiagnosticBeacon:
            if #available(iOS 14.0, macOS 12, *) {
                cbeacon.append(item, session: session)
            }
        case let item as SessionProfileBeacon:
            cbeacon.append(item)
        case let item as CustomBeacon:
            cbeacon.append(item, properties: properties)
        default:
            let message = "Beacon <-> CoreBeacon mapping for beacon \(beacon) not defined"
            debugAssertFailure(message)
            session.logger.add(message, level: .error)
            throw InstanaError.unknownType(message)
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
        let localMeta = properties.getMetaData()
        m = !localMeta.isEmpty ? localMeta : nil
    }

    mutating func append(_ beacon: HTTPBeacon) {
        t = .httpRequest
        bt = beacon.backendTracingID
        hu = beacon.url.absoluteString
        hp = beacon.path
        h = beacon.header
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
        if beacon.duration != nil {
            d = String(beacon.duration!)
        }

        im = MetaData()
        if beacon.accessibilityLabel != nil {
            im![internalMetaDataKeyView_accbltyLabel] = beacon.accessibilityLabel!
        }
        if beacon.navigationItemTitle != nil {
            im![internalMetaDataKeyView_navItemTitle] = beacon.navigationItemTitle!
        }
        if beacon.className != nil {
            im![internalMetaDataKeyView_className] = beacon.className!
        }
        if !beacon.viewInternalCPMetaMap.isEmpty {
            for (key, value) in beacon.viewInternalCPMetaMap {
                im![key] = value
            }
        }
        if im!.isEmpty {
            im = nil
        }
    }

    mutating func append(_ beacon: DroppedBeacons) {
        t = .dropBeacon
        im = beacon.beaconsMap
    }

    mutating func append(_ beacon: PerformanceBeacon) {
        t = .perf

        switch beacon {
        case let item as PerfAppLaunchBeacon:
            appendPerfAppLaunch(item)
        case let item as PerfAppNotRespondingBeacon:
            appendPerfAppNotResponding(item)
        case let item as PerfLowMemoryBeacon:
            appendPerfLowMemory(item)
        default:
            let message = "Beacon <-> CoreBeacon mapping for performance beacon \(beacon) not defined"
            debugAssertFailure(message)
        }
    }

    mutating func appendPerfAppLaunch(_ beacon: PerfAppLaunchBeacon) {
        pst = "ast"
        if beacon.appColdStartTime != nil {
            acs = String(beacon.appColdStartTime!)
        }
        if beacon.appWarmStartTime != nil {
            aws = String(beacon.appWarmStartTime!)
        }
        if beacon.appHotStartTime != nil {
            ahs = String(beacon.appHotStartTime!)
        }
    }

    mutating func appendPerfAppNotResponding(_ beacon: PerfAppNotRespondingBeacon) {
        pst = "anr"
        d = String(beacon.duration)
    }

    mutating func appendPerfLowMemory(_ beacon: PerfLowMemoryBeacon) {
        pst = "oom"
        if beacon.maximumMemory != nil {
            mmb = String(beacon.maximumMemory!)
        }
        if beacon.availableMemory != nil {
            amb = String(beacon.availableMemory!)
        }
        if beacon.usedMemory != nil {
            umb = String(beacon.usedMemory!)
        }
    }

    @available(iOS 14.0, macOS 12.0, *)
    mutating func append(_ beacon: DiagnosticBeacon, session: InstanaSession) {
        t = .crash

        let currentSID = sid
        let currentCN = cn
        let currentCT = ct
        let currentUI = ui
        let currentUN = un
        let currentUE = ue

        cti = String(beacon.crashTime)
        d = String(beacon.duration)
        if beacon.formatted != nil {
            st = beacon.formatted
        }
        if beacon.errorType != nil {
            et = String(beacon.errorType!)
        }
        if beacon.errorMessage != nil {
            em = beacon.errorMessage
        }

        sid = beacon.crashSession.id.uuidString
        v = beacon.crashSession.viewName
        cn = beacon.crashSession.carrier
        ct = beacon.crashSession.connectionType
        ui = beacon.crashSession.userID
        un = beacon.crashSession.userName
        ue = beacon.crashSession.userEmail
        cas = nil

        m = MetaData()
        m![crashMetaKeyIsSymbolicated] = String(beacon.isSymbolicated)
        m![crashMetaKeyInstanaPayloadVersion] = currentInstanaCrashPayloadVersion
        m![crashMetaKeyCrashType] = beacon.crashType?.rawValue
        m![crashMetaKeyGroupID] = beacon.crashGroupID.uuidString
        m![crashMetaKeySessionID] = currentSID
        let activeViewName = session.propertyHandler.properties.viewName
        if activeViewName != nil {
            m![crashMetaKeyViewName] = activeViewName
        }
        m![crashMetaKeyCarrier] = currentCN
        m![crashMetaKeyConnectionType] = currentCT
        m![crashMetaKeyUserID] = currentUI
        m![crashMetaKeyUserName] = currentUN
        m![crashMetaKeyUserEmail] = currentUE
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
        m = beacon.metaData
        if let error = beacon.error {
            add(error: error)
        }
        if let duration = beacon.duration {
            d = String(Int(duration))
        }
        if let tracingID = beacon.backendTracingID {
            bt = tracingID
        }
        if let customMetric = beacon.customMetric {
            cm = String(customMetric)
        }
        if let eventType = beacon.eventType {
            im = MetaData()
            im![internalMetaDataKeyCustom_eventType] = eventType
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

    // swiftlint:disable function_parameter_count
    static func createDefault(viewName: String?,
                              key: String,
                              timestamp: Instana.Types.Milliseconds,
                              sid: UUID,
                              usi: UUID?,
                              id: String,
                              mobileFeatures: String?,
                              trustDeviceTiming: Bool? = nil,
                              hybridAgentId: String?,
                              hybridAgentVersion: String?,
                              connection: NetworkUtility.ConnectionType = InstanaSystemUtils.networkUtility.connectionType,
                              ect: NetworkUtility.CellularType? = nil,
                              enableAppStateDetection: Bool? = nil)
        -> CoreBeacon {
        let cas = (enableAppStateDetection != false) ? InstanaApplicationStateHandler.shared.getAppStateForBeacon() : nil
        return CoreBeacon(v: viewName,
                          k: key,
                          ti: String(timestamp),
                          sid: sid.uuidString,
                          usi: usi?.uuidString,
                          bid: id,
                          uf: mobileFeatures,
                          bi: InstanaSystemUtils.applicationBundleIdentifier,
                          ul: Locale.current.languageCode,
                          ab: InstanaSystemUtils.applicationBuildNumber,
                          av: InstanaSystemUtils.applicationVersion,
                          p: InstanaSystemUtils.systemName,
                          osn: InstanaSystemUtils.systemName,
                          osv: InstanaSystemUtils.systemVersion,
                          dmo: InstanaSystemUtils.deviceModel,
                          agv: CoreBeacon.getInstanaAgentVersion(hybridAgentId: hybridAgentId,
                                                                 hybridAgentVersion: hybridAgentVersion),
                          ro: String(InstanaSystemUtils.isDeviceJailbroken),
                          vw: String(Int(InstanaSystemUtils.screenSize.width)),
                          vh: String(Int(InstanaSystemUtils.screenSize.height)),
                          cn: connection.cellular.carrierName,
                          ct: connection.description,
                          ect: ect?.description ?? connection.cellular.description,
                          tdt: trustDeviceTiming.map { $0 ? "1" : nil } ?? nil,
                          cas: cas)
    }
}
