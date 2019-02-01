//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

struct InstanaConfiguration {
    enum Defaults {
        static let reportingUrl = "http://localhost:3000"
        static let remoteCallInstrumentationType = InstanaRemoteCallInstrumentation.ReportingType.automaticAndManual
        static let eventsBufferSize = 200
        static let suspendReporting = InstanaEvents.SuspendReporting.never
        static let sendDeviceLocationIfAvailable = false
        static let alertLowMemory = false
    }
    
    let reportingUrl: String
    let key: String
    let remoteCallInstrumentationType: InstanaRemoteCallInstrumentation.ReportingType
    let enableCrashReporting: Bool
    let suspendReporting: InstanaEvents.SuspendReporting
    let eventsBufferSize: Int
    let sendDeviceLocationIfAvailable: Bool
    let alertApplicationNotRespondingTreshold: Instana.Types.Seconds?
    let alertLowMemory: Bool
    let alertFramerateDipTreshold: UInt?
    
    static func read(from path: String?) -> InstanaConfiguration? {
        guard let path = path, let config = NSDictionary(contentsOfFile: path) else {
            Instana.log.add("Couldn't locate configuration file")
            return nil
        }
        return read(from: config)
    }
    
    private static func read(from dictionary: NSDictionary) -> InstanaConfiguration? {
        guard let key = dictionary.value(forKey: "key") as? String else {
            Instana.log.add("Value for \"key\" missing in configuration file")
            return nil
        }

        return self.init(reportingUrl: dictionary.value(forKey: "reportingUrl") as? String ?? Defaults.reportingUrl,
                         key: key,
                         remoteCallInstrumentationType: dictionary.fromRawValue(forKey: "remoteCallInstrumentationType") ?? Defaults.remoteCallInstrumentationType,
                         enableCrashReporting: dictionary.bool(forKey: "enableCrashReporting", fallback: true),
                         suspendReporting: dictionary.fromRawValue(forKey: "suspendReporting") ?? Defaults.suspendReporting,
                         eventsBufferSize: dictionary.value(forKey: "eventsBufferSize") as? Int ?? Defaults.eventsBufferSize,
                         sendDeviceLocationIfAvailable: dictionary.bool(forKey: "sendDeviceLocationIfAvailable", fallback: Defaults.sendDeviceLocationIfAvailable),
                         alertApplicationNotRespondingTreshold: dictionary.value(forKey: "alertApplicationNotRespondingTreshold") as? Instana.Types.Seconds,
                         alertLowMemory: dictionary.bool(forKey: "alertLowMemory", fallback: Defaults.alertLowMemory),
                         alertFramerateDipTreshold: dictionary.value(forKey: "alertFramerateDipTreshold") as? UInt)
    }
    
    static func `default`(key: String, reportingUrl: String?) -> InstanaConfiguration {
        return self.init(reportingUrl: reportingUrl ?? Defaults.reportingUrl,
                         key: key,
                         remoteCallInstrumentationType: Defaults.remoteCallInstrumentationType,
                         enableCrashReporting: true,
                         suspendReporting: Defaults.suspendReporting,
                         eventsBufferSize: Defaults.eventsBufferSize,
                         sendDeviceLocationIfAvailable: Defaults.sendDeviceLocationIfAvailable,
                         alertApplicationNotRespondingTreshold: nil,
                         alertLowMemory: Defaults.alertLowMemory,
                         alertFramerateDipTreshold: nil)
    }
}

private extension NSDictionary {
    func bool(forKey key: String, fallback: Bool) -> Bool {
        return value(forKey: key) as? Bool ?? fallback
    }
    
    func fromRawValue<T: RawRepresentable>(forKey key: String) -> T? {
        guard let raw = value(forKey: key) as? T.RawValue else { return nil }
        return T.init(rawValue: raw)
    }
}
