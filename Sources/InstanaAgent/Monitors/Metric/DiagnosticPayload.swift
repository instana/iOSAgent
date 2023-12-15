//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
    import MetricKit
#endif

enum CrashType: String, Equatable, Codable, CustomStringConvertible {
    case crash // crash
    case hang // hang
    case cpu // CPU exception
    case disk // disk write exception
    case app // app launch exception
    var description: String { rawValue }
}

class DiagnosticPayload: Codable {
    let crashSession: PreviousSession
    // group id for all related crashes
    let crashGroupID: UUID
    let crashType: CrashType?
    let crashTime: Instana.Types.Milliseconds
    let duration: Instana.Types.Milliseconds
    let rawMXPayload: String?
    let errorType: Int?
    let errorMessage: String?
    let payloadVersion: String?
    let callStackTree: CallStackTree?
    // meta data
    let bundleIdentifier: String?
    let appBuildVersion: String?
    let appVersion: String?
    let osVersion: String?
    let deviceType: String?
    let platformArchitecture: String?
    // crash
    let exceptionType: Int?
    let exceptionCode: Int?
    let signal: Int?
    let terminationReason: String?
    let virtualMemoryRegionInfo: String?
    // cpu
    let totalCPUTime: String?
    let totalSampledTime: String?
    // disk write
    let writesCaused: String?
    // hang
    let hangDuration: String?
    // app launch
    let launchDuration: String?

    var isSymbolicated: Bool?
    var fileURL: URL?

    private enum CodingKeys: String, CodingKey {
        case crashSession
        case crashGroupID
        case crashType
        case crashTime
        case duration
        case rawMXPayload
        case errorType
        case errorMessage
        case payloadVersion
        case callStackTree
        case bundleIdentifier
        case appBuildVersion
        case appVersion
        case osVersion
        case deviceType
        case platformArchitecture
        case exceptionType // crash
        case exceptionCode
        case signal
        case terminationReason
        case virtualMemoryRegionInfo
        case totalCPUTime // cpu
        case totalSampledTime
        case writesCaused // diskWrite
        case hangDuration // hang
        case launchDuration // appLaunch
    }

    init(crashSession: PreviousSession,
         crashGroupID: UUID,
         crashType: CrashType?,
         crashTime: Instana.Types.Milliseconds,
         duration: Instana.Types.Milliseconds,
         rawMXPayload: String?,
         errorType: Int?,
         errorMessage: String?,
         payloadVersion: String?,
         callStackTree: CallStackTree?,
         bundleIdentifier: String?,
         appBuildVersion: String?,
         appVersion: String?,
         osVersion: String?,
         deviceType: String?,
         platformArchitecture: String?,
         exceptionType: Int?,
         exceptionCode: Int?,
         signal: Int?,
         terminationReason: String?,
         virtualMemoryRegionInfo: String?,
         totalCPUTime: String?,
         totalSampledTime: String?,
         writesCaused: String?,
         hangDuration: String?,
         launchDuration: String?,
         isSymbolicated: Bool) {
        self.crashSession = crashSession
        self.crashGroupID = crashGroupID
        self.crashType = crashType
        self.crashTime = crashTime
        self.duration = duration
        self.rawMXPayload = rawMXPayload
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.payloadVersion = payloadVersion
        self.callStackTree = callStackTree
        self.bundleIdentifier = bundleIdentifier
        self.appBuildVersion = appBuildVersion
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.deviceType = deviceType
        self.platformArchitecture = platformArchitecture
        self.exceptionType = exceptionType
        self.exceptionCode = exceptionCode
        self.signal = signal
        self.terminationReason = terminationReason
        self.virtualMemoryRegionInfo = virtualMemoryRegionInfo
        self.totalCPUTime = totalCPUTime
        self.totalSampledTime = totalSampledTime
        self.writesCaused = writesCaused
        self.hangDuration = hangDuration
        self.launchDuration = launchDuration

        self.isSymbolicated = isSymbolicated
        fileURL = nil
    }

    func serialize(fileURL: URL) {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            Instana.current?.session.logger.add("Diagnostic payload is saved to \(fileURL) successfully", level: .debug)
        } catch {
            Instana.current?.session.logger.add("Diagnostic payload save to \(fileURL) error \(error)", level: .error)
        }
    }

    @available(iOS 14.0, macOS 12, *)
    static func createDiagnosticPayloads(crashSession: PreviousSession,
                                         crashGroupID: UUID,
                                         payload: MXDiagnosticPayload) -> [DiagnosticPayload] {
        let startTime = payload.timeStampBegin.millisecondsSince1970
        let duration = payload.timeStampEnd.millisecondsSince1970 - startTime

        var plds = [DiagnosticPayload]()

        let crashBeacons = Self.createDiagnosticPayloadsOfType(
            crashSession: crashSession,
            crashGroupID: crashGroupID,
            diagnostics: payload.crashDiagnostics,
            startTime: startTime,
            duration: duration)
        plds.append(contentsOf: crashBeacons)

        let cpuExceptionBeacons = Self.createDiagnosticPayloadsOfType(
            crashSession: crashSession,
            crashGroupID: crashGroupID,
            diagnostics: payload.cpuExceptionDiagnostics,
            startTime: startTime,
            duration: duration)
        plds.append(contentsOf: cpuExceptionBeacons)

        let hangBeacons = Self.createDiagnosticPayloadsOfType(
            crashSession: crashSession,
            crashGroupID: crashGroupID,
            diagnostics: payload.hangDiagnostics,
            startTime: startTime,
            duration: duration)
        plds.append(contentsOf: hangBeacons)

        let diskWriteExceptionBeacons = Self.createDiagnosticPayloadsOfType(
            crashSession: crashSession,
            crashGroupID: crashGroupID,
            diagnostics: payload.diskWriteExceptionDiagnostics,
            startTime: startTime,
            duration: duration)
        plds.append(contentsOf: diskWriteExceptionBeacons)

        #if os(iOS)
            if #available(iOS 16.0, *) {
                let appLaunchBeacons = Self.createDiagnosticPayloadsOfType(
                    crashSession: crashSession,
                    crashGroupID: crashGroupID,
                    diagnostics: payload.appLaunchDiagnostics,
                    startTime: startTime,
                    duration: duration)
                plds.append(contentsOf: appLaunchBeacons)
            }
        #endif
        return plds
    }

    @available(iOS 14.0, macOS 12, *)
    static func createDiagnosticPayloadsOfType(crashSession: PreviousSession,
                                               crashGroupID: UUID,
                                               diagnostics: [MXDiagnostic]?,
                                               startTime: Instana.Types.Milliseconds,
                                               duration: Instana.Types.Milliseconds) -> [DiagnosticPayload] {
        guard diagnostics != nil else { return [] }

        var plds = [DiagnosticPayload]()
        for oneDiag in diagnostics! {
            var payloadVersion: String?
            var bundleIdentifier: String?
            let appBuildVersion = oneDiag.metaData.applicationBuildVersion
            var appVersion: String?
            let osVersion = oneDiag.metaData.osVersion
            var deviceType: String?
            var platformArchitecture: String?
            var exceptionType: Int? // crash
            var exceptionCode: Int?
            var signal: Int?
            var terminationReason: String?
            var virtualMemoryRegionInfo: String?
            var totalCPUTime: String? // cpu
            var totalSampledTime: String?
            var writesCaused: String? // diskWrite
            var hangDuration: String? // hang
            var launchDuration: String? // appLaunch

            let (crashType, mxCallStackTree) = Self.parseCrashTypeAndCallStackTree(diagnostic: oneDiag)
            guard let mxCallStackTree = mxCallStackTree else { continue }
            let callStackTree = CallStackTree.deserialize(data: mxCallStackTree.jsonRepresentation())
            guard callStackTree != nil else { continue }

            let dict = oneDiag.dictionaryRepresentation()
            if let rawPayloadVersion = dict["version"] {
                payloadVersion = rawPayloadVersion as? String
            }

            if let diagnosticMetaData = dict["diagnosticMetaData"],
                let metaDict = diagnosticMetaData as? [AnyHashable: Any] {
                appVersion = metaDict["appVersion"] as? String
                bundleIdentifier = metaDict["bundleIdentifier"] as? String
                deviceType = metaDict["deviceType"] as? String
                platformArchitecture = metaDict["platformArchitecture"] as? String
                exceptionType = metaDict["exceptionType"] as? Int // crash
                exceptionCode = metaDict["exceptionCode"] as? Int
                signal = metaDict["signal"] as? Int
                terminationReason = metaDict["terminationReason"] as? String
                virtualMemoryRegionInfo = metaDict["virtualMemoryRegionInfo"] as? String
                totalCPUTime = metaDict["totalCPUTime"] as? String // cpu
                totalSampledTime = metaDict["totalSampledTime"] as? String
                writesCaused = metaDict["writesCaused"] as? String // diskWrite
                hangDuration = metaDict["hangDuration"] as? String // hang
                launchDuration = metaDict["launchDuration"] as? String // appLaunch
            }

            let (errorType, errorMessage) = Self.parseErrorTypeAndMessage(crashType: crashType!, diagnostic: oneDiag)
            guard errorMessage != nil else { continue }
            let rawMXPayload = Self.getMXPayloadStr(diagnostic: oneDiag)
            guard rawMXPayload != nil else { continue }

            plds.append(DiagnosticPayload(crashSession: crashSession,
                                          crashGroupID: crashGroupID,
                                          crashType: crashType,
                                          crashTime: startTime,
                                          duration: duration,
                                          rawMXPayload: rawMXPayload,
                                          errorType: errorType,
                                          errorMessage: errorMessage,
                                          payloadVersion: payloadVersion,
                                          callStackTree: callStackTree,
                                          bundleIdentifier: bundleIdentifier,
                                          appBuildVersion: appBuildVersion,
                                          appVersion: appVersion,
                                          osVersion: osVersion,
                                          deviceType: deviceType,
                                          platformArchitecture: platformArchitecture,
                                          exceptionType: exceptionType,
                                          exceptionCode: exceptionCode,
                                          signal: signal,
                                          terminationReason: terminationReason,
                                          virtualMemoryRegionInfo: virtualMemoryRegionInfo,
                                          totalCPUTime: totalCPUTime,
                                          totalSampledTime: totalSampledTime,
                                          writesCaused: writesCaused,
                                          hangDuration: hangDuration,
                                          launchDuration: launchDuration,
                                          isSymbolicated: false))
        }
        return plds
    }

    @available(iOS 14.0, macOS 12, *)
    static func parseCrashTypeAndCallStackTree(diagnostic: MXDiagnostic) -> (CrashType?, MXCallStackTree?) {
        var crashType: CrashType?
        var callStackTree: MXCallStackTree?

        if diagnostic as? MXCrashDiagnostic != nil {
            crashType = .crash
            callStackTree = (diagnostic as? MXCrashDiagnostic)!.callStackTree
        } else if diagnostic as? MXCPUExceptionDiagnostic != nil {
            crashType = .cpu
            callStackTree = (diagnostic as? MXCPUExceptionDiagnostic)!.callStackTree
        } else if diagnostic as? MXHangDiagnostic != nil {
            crashType = .hang
            callStackTree = (diagnostic as? MXHangDiagnostic)!.callStackTree
        } else if diagnostic as? MXDiskWriteExceptionDiagnostic != nil {
            crashType = .disk
            callStackTree = (diagnostic as? MXDiskWriteExceptionDiagnostic)!.callStackTree
        } else if #available(iOS 16.0, *) {
            #if os(iOS)
                if diagnostic as? MXAppLaunchDiagnostic != nil {
                    crashType = .app
                    callStackTree = (diagnostic as? MXAppLaunchDiagnostic)!.callStackTree
                }
            #endif
        }
        return (crashType, callStackTree)
    }

    @available(iOS 14.0, macOS 12, *)
    static func getMXPayloadStr(diagnostic: MXDiagnostic) -> String? {
        let treeData = diagnostic.jsonRepresentation()
        do {
            let dict = try JSONSerialization.jsonObject(with: treeData, options: []) as? [AnyHashable: Any]
            if dict != nil {
                return dict!.asJsonStr()
            }
        } catch {
            Instana.current?.session.logger.add("Diagnostic payload parsing error \(error)", level: .error)
        }
        return nil
    }

    @available(iOS 14.0, macOS 12, *)
    static func parseErrorTypeAndMessage(crashType: CrashType, diagnostic: MXDiagnostic) -> (Int?, String?) {
        var errorCode: Int?
        var errorMsg: String?

        switch crashType {
        case .app:
            errorMsg = "app launch diagnostic"
        case .cpu:
            errorMsg = "cpu exception diagnostic"
        case .disk:
            errorMsg = "disk write exception diagnostic"
        case .hang:
            errorMsg = "hang diagnostic"
        case .crash:
            (errorCode, errorMsg) = Self.parseCrashErrorTypeAndMessage(diagnostic: diagnostic)
        }
        return (errorCode, errorMsg)
    }

    @available(iOS 14.0, macOS 12, *)
    static func parseCrashErrorTypeAndMessage(diagnostic: MXDiagnostic) -> (Int?, String?) {
        guard let crashDiag = diagnostic as? MXCrashDiagnostic else {
            return (nil, "crash diagnostic")
        }

        let exceptionType = crashDiag.exceptionType
        let exceptionCode = crashDiag.exceptionCode
        let signal = crashDiag.signal

        var errorCode: Int?
        var errorMsg: String = ""
        let machExceptionType = Self.getMachExceptionTypeDisplayName(exceptionType: exceptionType)
        let machExceptionCode = Self.getMachExceptionCodeDisplayName(exceptionType: exceptionType,
                                                                     exceptionCode: exceptionCode)
        let sigName = Self.getSignalName(signal: signal)

        if machExceptionType != nil {
            errorMsg = machExceptionType!
        }
        if sigName != nil {
            errorMsg += " (\(sigName!))"
        }
        if machExceptionCode != nil {
            errorMsg += " - \(machExceptionCode!)"
        }

        if errorMsg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMsg = "unkown error"
        }

        if exceptionType != nil {
            errorCode = Int(truncating: exceptionType!)
        } else if signal != nil {
            errorCode = Int(truncating: signal!)
        }

        return (errorCode, errorMsg)
    }

    static func getMachExceptionTypeDisplayName(exceptionType: NSNumber?) -> String? {
        guard let exceptionType = exceptionType else {
            return nil
        }

        switch Int32(truncating: exceptionType) {
        case EXC_BAD_ACCESS: // 1
            return "EXC_BAD_ACCESS"
        case EXC_BAD_INSTRUCTION: // 2
            return "EXC_BAD_INSTRUCTION"
        case EXC_ARITHMETIC: // 3
            return "EXC_ARITHMETIC"
        case EXC_BREAKPOINT: // 6
            return "EXC_BREAKPOINT"
        case EXC_CRASH: // 10
            return "EXC_CRASH"
        case EXC_RESOURCE: // 11
            return "EXC_RESOURCE"
        case EXC_GUARD: // 12
            return "EXC_GUARD"
        default:
            return exceptionType.stringValue
        }
    }

    static func getMachExceptionCodeDisplayName(exceptionType: NSNumber?, exceptionCode: NSNumber?) -> String? {
        guard let exceptionCode = exceptionCode else {
            return nil
        }

        if exceptionType != nil, Int32(truncating: exceptionType!) == EXC_BAD_ACCESS {
            switch Int32(truncating: exceptionCode) {
            case KERN_INVALID_ADDRESS: // 1
                return "KERN_INVALID_ADDRESS"
            case KERN_PROTECTION_FAILURE: // 2
                return "KERN_PROTECTION_FAILURE"
            default:
                return exceptionCode.stringValue
            }
        }
        return exceptionCode.stringValue
    }

    static func getSignalName(signal: NSNumber?) -> String? {
        guard let signal = signal else {
            return nil
        }
        switch Int32(truncating: signal) {
        case SIGQUIT: // 3
            return ("SIGQUIT")
        case SIGILL: // 4
            return ("SIGILL")
        case SIGTRAP: // 5
            return ("SIGTRAP")
        case SIGABRT: // 6
            return ("SIGABRT - ABORT")
        case SIGFPE: // 8
            return ("SIGFPE")
        case SIGKILL: // 9
            return ("SIGKILL")
        case SIGBUS: // 10
            return ("SIGBUS")
        case SIGSEGV: // 11
            return ("SIGSEGV")
        case SIGSYS: // 12
            return ("SIGSYS")
        default:
            return (signal.stringValue)
        }
    }
}

extension DiagnosticPayload {
    static func deserialize(fileURL: URL) -> DiagnosticPayload? {
        do {
            let data = try Data(contentsOf: fileURL)
            let payload = try JSONDecoder().decode(DiagnosticPayload.self, from: data)
            payload.fileURL = fileURL
            if !PreviousSession.isCrashTimeWithinRange(payload.crashTime) {
                payload.deletePayloadFile()
                return nil
            }
            return payload
        } catch {
            Instana.current?.session.logger.add("Error deserialize \(fileURL)", level: .error)
        }
        return nil
    }

    @discardableResult func deletePayloadFile() -> Bool {
        guard let fileURL = fileURL else { return false }
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            Instana.current?.session.logger.add("Error \(error) delete \(fileURL)", level: .error)
        }
        return false
    }

    public static func canSymbolicate(bundleIdentifier: String?,
                                      appBuildVersion: String?,
                                      osVersion: String?) -> Bool {
        #if os(iOS)
            guard let bundleIdentifier = bundleIdentifier,
                let appBuildVersion = appBuildVersion,
                let osVersion = osVersion else { return false }

            guard InstanaSystemUtils.applicationBundleIdentifier == bundleIdentifier else { return false }

            guard InstanaSystemUtils.applicationBuildNumber == appBuildVersion else { return false }

            var currentOSVersion: String
            let osv = ProcessInfo.processInfo.operatingSystemVersion
            if osv.patchVersion > 0 {
                currentOSVersion = " \(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion) "
            } else {
                currentOSVersion = " \(osv.majorVersion).\(osv.minorVersion) "
            }
            if !osVersion.contains(currentOSVersion) { return false }

            return true
        #else
            return false
        #endif
    }

    func canSymbolicate() -> Bool {
        if callStackTree == nil { return false }
        return Self.canSymbolicate(bundleIdentifier: bundleIdentifier,
                                   appBuildVersion: appBuildVersion,
                                   osVersion: osVersion)
    }
}
