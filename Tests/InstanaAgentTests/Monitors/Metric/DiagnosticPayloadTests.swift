//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
import MetricKit
#endif
import XCTest
@testable import InstanaAgent

@available(iOS 14.0, macOS 12.0, *)
class MXDiagnostic_jsonRepresentationInvalid: MXDiagnostic {
    override func jsonRepresentation() -> Data {
        return "invalidJsonString".data(using: .utf8)!
    }
}

class DiagnosticPayloadTests: InstanaTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    @available(iOS 14.0, macOS 12, *)
    func test_getMXPayloadStr() {
        // Given
        let diagnostic = MXDiagnostic_jsonRepresentationInvalid()

        // When
        let payloadStr = DiagnosticPayload.getMXPayloadStr(diagnostic: diagnostic)

        // Then
        XCTAssertEqual(payloadStr, payloadStr)
    }

    @available(iOS 14.0, macOS 12, *)
    func test_parseCrashErrorTypeAndMessage() {
        // Given
        let diagnostic = MXCrashDiagnosticMock()

        // When
        let (type, msg) = DiagnosticPayload.parseCrashErrorTypeAndMessage(diagnostic: diagnostic)

        // Then
        XCTAssertEqual(type, 10)
        XCTAssertEqual(msg, "EXC_CRASH (SIGABRT - ABORT) - 0")
    }

    @available(iOS 14.0, macOS 12, *)
    func test_parseCrashErrorTypeAndMessage_neg() {
        // Given
        // MXCrashDiagnostic is expected
        let diagnostic = MXCPUExceptionDiagnostic()

        // When
        let (type, msg) = DiagnosticPayload.parseCrashErrorTypeAndMessage(diagnostic: diagnostic)

        // Then
        XCTAssertNil(type)
        XCTAssertEqual(msg, "crash diagnostic")
    }

    func test_getMachExceptionTypeDisplayName() {
        var ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_BAD_ACCESS as NSNumber)
        XCTAssertEqual(ret, "EXC_BAD_ACCESS") //1

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_BAD_INSTRUCTION as NSNumber)
        XCTAssertEqual(ret, "EXC_BAD_INSTRUCTION") //2

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_ARITHMETIC as NSNumber)
        XCTAssertEqual(ret, "EXC_ARITHMETIC") //3

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: 4)
        XCTAssertEqual(ret, "4") //4

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_BREAKPOINT as NSNumber)
        XCTAssertEqual(ret, "EXC_BREAKPOINT") //6

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_CRASH as NSNumber)
        XCTAssertEqual(ret, "EXC_CRASH") //10

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_RESOURCE as NSNumber)
        XCTAssertEqual(ret, "EXC_RESOURCE") //11

        ret = DiagnosticPayload.getMachExceptionTypeDisplayName(exceptionType: EXC_GUARD as NSNumber)
        XCTAssertEqual(ret, "EXC_GUARD") //12
    }

    func test_getMachExceptionCodeDisplayName() {
        var ret = DiagnosticPayload.getMachExceptionCodeDisplayName(exceptionType: 111 as NSNumber, exceptionCode: nil)
        XCTAssertNil(ret)

        ret = DiagnosticPayload.getMachExceptionCodeDisplayName(exceptionType: EXC_BAD_ACCESS as NSNumber, exceptionCode: nil)
        XCTAssertNil(ret)

        ret = DiagnosticPayload.getMachExceptionCodeDisplayName(exceptionType: EXC_BAD_ACCESS as NSNumber, exceptionCode: 1)
        XCTAssertEqual(ret, "KERN_INVALID_ADDRESS")

        ret = DiagnosticPayload.getMachExceptionCodeDisplayName(exceptionType: EXC_BAD_ACCESS as NSNumber, exceptionCode: 2)
        XCTAssertEqual(ret, "KERN_PROTECTION_FAILURE")

        ret = DiagnosticPayload.getMachExceptionCodeDisplayName(exceptionType: EXC_BAD_ACCESS as NSNumber, exceptionCode: 3)
        XCTAssertEqual(ret, "3")
    }

    func test_getSignalName() {
        var sig = DiagnosticPayload.getSignalName(signal: SIGABRT as NSNumber)
        XCTAssertEqual(sig, "SIGABRT - ABORT") //6

        sig = DiagnosticPayload.getSignalName(signal: SIGBUS as NSNumber)
        XCTAssertEqual(sig, "SIGBUS") //10

        sig = DiagnosticPayload.getSignalName(signal: SIGFPE as NSNumber)
        XCTAssertEqual(sig, "SIGFPE") //8

        sig = DiagnosticPayload.getSignalName(signal: SIGILL as NSNumber)
        XCTAssertEqual(sig, "SIGILL") //4

        sig = DiagnosticPayload.getSignalName(signal: SIGSEGV as NSNumber)
        XCTAssertEqual(sig, "SIGSEGV") //11

        sig = DiagnosticPayload.getSignalName(signal: SIGSYS as NSNumber)
        XCTAssertEqual(sig, "SIGSYS") //12

        sig = DiagnosticPayload.getSignalName(signal: SIGTRAP as NSNumber)
        XCTAssertEqual(sig, "SIGTRAP") //5

        sig = DiagnosticPayload.getSignalName(signal: 222 as NSNumber)
        XCTAssertEqual(sig, "222")
    }

    func test_canSymbolicate() {
        var ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: nil, appBuildVersion: "mockAppVer", osVersion: "mockOSVer")
        XCTAssertFalse(ret)

        ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: "mockBID", appBuildVersion: nil, osVersion: "mockOSVer")
        XCTAssertFalse(ret)

        ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: "mockBID", appBuildVersion: "mockAppVer", osVersion: nil)
        XCTAssertFalse(ret)

        ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: "mockBID", appBuildVersion: "mockAppVer", osVersion: "mockOSVer")
        XCTAssertFalse(ret)

        ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: InstanaSystemUtils.applicationBundleIdentifier,
                                               appBuildVersion: "mockAppVer", osVersion: "mockOSVer")
        XCTAssertFalse(ret)

        ret = DiagnosticPayload.canSymbolicate(bundleIdentifier: InstanaSystemUtils.applicationBundleIdentifier,
                                               appBuildVersion: InstanaSystemUtils.applicationBuildNumber,
                                               osVersion: "mockOSVer")
        XCTAssertFalse(ret)
    }
}
