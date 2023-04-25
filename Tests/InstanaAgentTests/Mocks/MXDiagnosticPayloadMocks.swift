//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
import MetricKit
#endif
import XCTest
@testable import InstanaAgent

let mockCrashDiagnosticStr = """
{
  "callStacks" : [
    {
        "threadAttributed" : true,
        "callStackRootFrames" : [
          {
            "binaryUUID" : "030D2641-514F-373F-9688-582D9D3B369A",
            "offsetIntoBinaryTextSegment" : 7977906176,
            "sampleCount" : 1,
            "binaryName" : "libsystem_pthread.dylib",
            "address" : 7977912628
          }
        ]
    }
  ],
  "callStackPerThread" : true
}
"""

let mockCpuDiagnosticStr = """
{
    "callStacks" : [
      {
        "callStackRootFrames" : [
          {
            "binaryUUID" : "948FB879-36CA-4799-932B-5B47CE5C2F9F",
            "offsetIntoBinaryTextSegment" : 123,
            "sampleCount" : 20,
            "binaryName" : "testBinaryName",
            "address" : 74565
          }
        ]
      }
    ],
    "callStackPerThread" : false
}
"""

let mockHangDiagnosticStr = mockCrashDiagnosticStr
let mockDiskWriteDiagnosticStr = mockCpuDiagnosticStr
let mockAppLaunchDiagnosticStr = mockCrashDiagnosticStr

// MARK: MXDiagnosticPayload mock

@available(iOS 14.0, macOS 12.0, *)
class MXDiagnosticPayloadMockBase: MXDiagnosticPayload {
    override var timeStampBegin: Date {
        return Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
    }
    override var timeStampEnd: Date {
        return Calendar.current.date(byAdding: .minute, value: -3, to: Date())!
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXDiagnosticPayloadMockAll: MXDiagnosticPayloadMockBase {
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return [MXCrashDiagnosticMock()]
    }

    override var cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic]? {
        return [MXCPUExceptionDiagnosticMock()]
    }

    override var diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic]? {
        return [MXDiskWriteExceptionDiagnosticMock()]
    }

    override var hangDiagnostics: [MXHangDiagnostic]? {
        return [MXHangDiagnosticMock()]
    }

    @available(iOS 16.0, *)
    override var appLaunchDiagnostics: [MXAppLaunchDiagnostic]? {
        return [MXAppLaunchDiagnosticMock()]
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXDiagnosticPayloadMockCrash_canNotSymbolicate: MXDiagnosticPayloadMockBase {
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return [MXCrashDiagnosticMock_canNotSymbolicate()]
    }
}

// MARK: MXDiagnostic (5 of them) mock

@available(iOS 14.0, macOS 12.0, *)
class MXCrashDiagnosticMock: MXCrashDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXCrashDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockCrash()
    }
    override var exceptionType: NSNumber? {
        return 10
    }
    override var exceptionCode: NSNumber? {
        return 0
    }
    override var terminationReason: String? {
        return "mock Crash Termination Reason"
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCrashDiagnosticMock_canNotSymbolicate: MXCrashDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock_canNotSymbolicate()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXCrashDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockCrash()
    }
    override var exceptionType: NSNumber? {
        return 1 //EXC_BAD_ACCESS
    }
    override var exceptionCode: NSNumber? {
        return 1 //KERN_INVALID_ADDRESS
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCPUExceptionDiagnosticMock: MXCPUExceptionDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXCPUExceptionDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockCPU()
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXDiskWriteExceptionDiagnosticMock: MXDiskWriteExceptionDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXDiskWriteDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockDiskWrite()
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXHangDiagnosticMock: MXHangDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXHangDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockHang()
    }
}

@available(iOS 16.0, *)
class MXAppLaunchDiagnosticMock: MXAppLaunchDiagnostic {
    override var metaData: MXMetaDataMock {
        return MXMetaDataMock()
    }
    override func dictionaryRepresentation() -> [AnyHashable : Any] {
        return getMXAppLaunchDiagnosticDictionaryRepresentation()
    }
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockAppLaunch()
    }
}

// MARK: MXCallStackTree mock

@available(iOS 14.0, macOS 12.0, *)
class MXCallStackTreeMockCrash: MXCallStackTree {
    override func jsonRepresentation() -> Data {
        return mockCrashDiagnosticStr.data(using: .utf8)!
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCallStackTreeMockCrash_invalidCallStackTreeJson: MXCallStackTree {
    // invalid json string to cover CallStackTree.deserialize() negative case
    override func jsonRepresentation() -> Data {
        return "".data(using: .utf8)!
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCallStackTreeMockCPU: MXCallStackTree {
    // also test missing threadAttributed key case
    override func jsonRepresentation() -> Data {
        return mockCpuDiagnosticStr.data(using: .utf8)!
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCallStackTreeMockHang: MXCallStackTree {
    override func jsonRepresentation() -> Data {
        return mockHangDiagnosticStr.data(using: .utf8)!
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCallStackTreeMockDiskWrite: MXCallStackTree {
    override func jsonRepresentation() -> Data {
        return mockDiskWriteDiagnosticStr.data(using: .utf8)!
    }
}

@available(iOS 16.0, *)
class MXCallStackTreeMockAppLaunch: MXCallStackTree {
    override func jsonRepresentation() -> Data {
        return mockAppLaunchDiagnosticStr.data(using: .utf8)!
    }
}


// MARK: MXMetaData mock

@available(iOS 13.0, macOS 12.0, *)
class MXMetaDataMock: MXMetaData {
    override var applicationBuildVersion: String {
        return InstanaSystemUtils.applicationBuildNumber
    }
    override var osVersion: String {
        //example "iPhone OS 15.7 (19H12)"
        var currentOSVersion: String
        let osv = ProcessInfo.processInfo.operatingSystemVersion
        if osv.patchVersion > 0 {
            currentOSVersion = " \(osv.majorVersion).\(osv.minorVersion).\(osv.patchVersion) "
        } else {
            currentOSVersion = " \(osv.majorVersion).\(osv.minorVersion) "
        }
        return "iPhone OS\(currentOSVersion)(19H12)"
    }
}

@available(iOS 13.0, macOS 12.0, *)
class MXMetaDataMock_canNotSymbolicate: MXMetaDataMock {
    override var osVersion: String {
        return "mockOSVersion"
    }
}

// MARK: MXCrashDiagnostic + MXDiagnostic for Crash signal test
@available(iOS 14.0, macOS 12.0, *)
class MXDiagnosticPayloadMockCrash_signalSIGSEGV: MXDiagnosticPayloadMockBase {
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return [MXCrashDiagnosticMock_forCrashSIGSEGV()]
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCrashDiagnosticMock_forCrashSIGSEGV: MXCrashDiagnosticMock {
    override var callStackTree: MXCallStackTree {
        return MXCallStackTreeMockCrash_invalidCallStackTreeJson()
    }
    override var exceptionType: NSNumber? {
        return nil
    }
    override var exceptionCode: NSNumber? {
        return nil
    }
    override var signal: NSNumber? {
        return 11 //SIGSEGV
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXCrashDiagnosticMock_forCrashSIGABRT: MXDiagnosticPayloadMockBase {
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return [MXDiagnosticPayloadMockCrash_signalSIGABRT()]
    }
}

@available(iOS 14.0, macOS 12.0, *)
class MXDiagnosticPayloadMockCrash_signalSIGABRT: MXCrashDiagnosticMock {
    override var exceptionType: NSNumber? {
        return nil
    }
    override var exceptionCode: NSNumber? {
        return nil
    }
    override var signal: NSNumber? {
        return 6 //SIGABRT
    }
}

// MARK: utility methods

func getMXDiagnosticDictionaryRepresentationBase() -> [AnyHashable : Any] {
    var dict = [AnyHashable : Any]()
    dict["version"] = "1.0.0"

    var metaDict = [AnyHashable : Any]()
    metaDict["platformArchitecture"] = "arm64"
    metaDict["appBuildVersion"] = "1"
    metaDict["appVersion"] = "1.0"
    metaDict["deviceType"] = "iPhone9,1"
    metaDict["bundleIdentifier"] = InstanaSystemUtils.applicationBundleIdentifier
    metaDict["regionFormat"] = "US"
    dict["diagnosticMetaData"] = metaDict
    return dict
}

func getMXCrashDiagnosticDictionaryRepresentation() -> [AnyHashable : Any] {
    var dict = getMXDiagnosticDictionaryRepresentationBase()
    var metaDict = (dict["diagnosticMetaData"] as? [AnyHashable : Any])!
    metaDict["terminationReason"] = "Namespace SIGNAL, Code 0xb"
    metaDict["exceptionType"] = 1
    metaDict["exceptionCode"] = 0
    metaDict["virtualMemoryRegionInfo"] = "mock MemoryRegionInfo string"
    metaDict["signal"] = 11
    dict["diagnosticMetaData"] = metaDict
    return dict
}

func getMXCPUExceptionDiagnosticDictionaryRepresentation() -> [AnyHashable : Any] {
    var dict = getMXDiagnosticDictionaryRepresentationBase()
    var metaDict = (dict["diagnosticMetaData"] as? [AnyHashable : Any])!
    metaDict["totalCPUTime"] = "20 sec"
    metaDict["totalSampledTime"] = "20 sec"
    dict["diagnosticMetaData"] = metaDict
    return dict
}

func getMXHangDiagnosticDictionaryRepresentation() -> [AnyHashable : Any] {
    var dict = getMXDiagnosticDictionaryRepresentationBase()
    var metaDict = (dict["diagnosticMetaData"] as? [AnyHashable : Any])!
    metaDict["hangDuration"] = "20 sec"
    dict["diagnosticMetaData"] = metaDict
    return dict
}

func getMXDiskWriteDiagnosticDictionaryRepresentation() -> [AnyHashable : Any] {
    var dict = getMXDiagnosticDictionaryRepresentationBase()
    var metaDict = (dict["diagnosticMetaData"] as? [AnyHashable : Any])!
    metaDict["writesCaused"] = "2000 byte"
    dict["diagnosticMetaData"] = metaDict
    return dict
}

func getMXAppLaunchDiagnosticDictionaryRepresentation() -> [AnyHashable : Any] {
    var dict = getMXDiagnosticDictionaryRepresentationBase()
    var metaDict = (dict["diagnosticMetaData"] as? [AnyHashable : Any])!
    metaDict["launchDuration"] = "20 sec"
    dict["diagnosticMetaData"] = metaDict
    return dict
}
