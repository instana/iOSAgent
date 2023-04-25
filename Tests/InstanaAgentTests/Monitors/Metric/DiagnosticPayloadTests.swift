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
        XCTAssertNotNil(type)
        XCTAssertEqual(msg, "mock Crash Termination Reason")
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

    func test_getMachExceptionName() {
        var ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_BAD_ACCESS as NSNumber,
                                                         exceptionCode: KERN_INVALID_ADDRESS as NSNumber)
        XCTAssertEqual(ret, "EXC_BAD_ACCESS - KERN_INVALID_ADDRESS") //1 - 1

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_BAD_ACCESS as NSNumber,
                                                         exceptionCode: KERN_PROTECTION_FAILURE as NSNumber)
        XCTAssertEqual(ret, "EXC_BAD_ACCESS - KERN_PROTECTION_FAILURE") //1 - 2

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_BAD_ACCESS as NSNumber,
                                                         exceptionCode: 333 as NSNumber)
        XCTAssertEqual(ret, "EXC_BAD_ACCESS - 333") //1 - 333

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_BAD_INSTRUCTION as NSNumber, exceptionCode: nil)
        XCTAssertEqual(ret, "EXC_BAD_INSTRUCTION") //2

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_ARITHMETIC as NSNumber, exceptionCode: nil)
        XCTAssertEqual(ret, "EXC_ARITHMETIC") //3

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_BREAKPOINT as NSNumber, exceptionCode: nil)
        XCTAssertEqual(ret, "EXC_BREAKPOINT") //6

        ret = DiagnosticPayload.getMachExceptionName(exceptionType: EXC_GUARD as NSNumber, exceptionCode: nil)
        XCTAssertEqual(ret, "EXC_GUARD") //12
    }

    func test_getMachExceptionBadAccessCodeName() {
        var ret = DiagnosticPayload.getMachExceptionBadAccessCodeName(exceptionType: 111 as NSNumber, exceptionCode: nil)
        XCTAssertNil(ret)

        ret = DiagnosticPayload.getMachExceptionBadAccessCodeName(exceptionType: EXC_BAD_ACCESS as NSNumber, exceptionCode: nil)
        XCTAssertNil(ret)
    }

    func test_getSignalName() {
        var (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGABRT as NSNumber)
        XCTAssertEqual(sig, "SIGABRT") //6
        XCTAssertEqual(sub, "ABORT")

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGBUS as NSNumber)
        XCTAssertEqual(sig, "SIGBUS") //10
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGFPE as NSNumber)
        XCTAssertEqual(sig, "SIGFPE") //8
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGILL as NSNumber)
        XCTAssertEqual(sig, "SIGILL") //4
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGSEGV as NSNumber)
        XCTAssertEqual(sig, "SIGSEGV") //11
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGSYS as NSNumber)
        XCTAssertEqual(sig, "SIGSYS") //12
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: SIGTRAP as NSNumber)
        XCTAssertEqual(sig, "SIGTRAP") //5
        XCTAssertNil(sub)

        (sig, sub) = DiagnosticPayload.getSignalName(signal: 222 as NSNumber)
        XCTAssertEqual(sig, "222")
        XCTAssertNil(sub)
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
