//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
import MetricKit
#endif
import XCTest
@testable import InstanaAgent


class MetricMonitorTests: InstanaTestCase {
    var metricMonitor: MetricMonitor?
    let mockReporter = MockReporter()

    override func setUp() {
        super.setUp()
        // delete diagnostic dir in case other test cases malfunctioned
        MetricMonitor.deleteDiagnosticFiles(includeDir: true)

        let prevSessionStartTime = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        session.previousSession = PreviousSession(id: UUID(),
                                    startTime: prevSessionStartTime,
                                    viewName: "mockViewName",
                                    carrier: nil,
                                    connectionType: nil,
                                    userID: nil,
                                    userEmail: "mockEmail@instana.com",
                                    userName: nil)
        self.metricMonitor = MetricMonitor(session, reporter: mockReporter)
    }

    override func tearDown() {
        metricMonitor = nil
        //delete files in "diagnostic" directory under cache
        MetricMonitor.deleteDiagnosticFiles(includeDir: true)
        super.tearDown()
    }

    func test_cancelCrashReporting() {
        // When
        var cancelled = self.metricMonitor!.cancelDiagnosticReporting()

        // Then
        // No symbolication operation going on, nothing is cancelled
        XCTAssertFalse(cancelled)

        // Then again, there is one SymbolicationOperation in Ready state
        metricMonitor!.symOp = SymbolicationOperation(metricMonitor: metricMonitor)
        cancelled = self.metricMonitor!.cancelDiagnosticReporting()
        XCTAssertTrue(cancelled)
    }

    @available(iOS 13.0, *)
    func test_didReceive_metricPayload() {
        // Given
        let payloads = [MXMetricPayload]()
        
        // When
        self.metricMonitor!.didReceive(payloads)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_didReceive_diagnosticPayload() {
        // Given
        let payloads = [MXDiagnosticPayloadMockAll()]

        // When
        self.metricMonitor!.didReceive(payloads)
        // Delay 2 seconds more to test DiagnosticPayload.deserialize()
        // Delay another 5 seconds more to test beacon submission
        // 5 diagnostic beacons to submit in this test case
        // 5 seconds sleep after previous diagnostic done. (5-1)*5=20
        Thread.sleep(forTimeInterval: 30)

        // Then
        // Diagnostic files are saved in cache directory
        // After diagnostic beacon is submitted, file is deleted
        XCTAssertEqual(metricMonitor?.processedFiles.count, 0)
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertFalse(fileExist!)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_didReceive_beaconSubmitFailed() {
        // Given
        let mockReporter = MockReporterDiagnostic_beaconSubmissionFailed()
        self.metricMonitor = MetricMonitor(session, reporter: mockReporter)
        let payloads = [MXDiagnosticPayloadMockCrash_canNotSymbolicate()]

        // When
        self.metricMonitor!.didReceive(payloads)
        // Delay 2 seconds more to test DiagnosticPayload.deserialize()
        // Delay another 5 seconds more to test beacon submission
        Thread.sleep(forTimeInterval: 10)

        // Then
        // There must be diagnostic file left in cache directory
        // on behalf of beacon submission failure
        XCTAssertEqual(metricMonitor?.processedFiles.count, 1)
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertTrue(fileExist!)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_didReceive_canNotSymbolicate() {
        // Given
        let payloads = [MXDiagnosticPayloadMockCrash_canNotSymbolicate()]

        // When
        self.metricMonitor!.didReceive(payloads)

        // Then
        // There must be diagnostic file saved in cache directory
        // because beacon submission code is not triggered
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertTrue(fileExist!)
        // With 2 seconds delay after diagnostic file is saved,
        // symbolication not started yet. So no files are being processed.
        XCTAssertEqual(metricMonitor?.processedFiles.count, 0)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_didReceive_crashSignal() {
        // Given
        let payloads = [MXDiagnosticPayloadMockCrash_signalSIGSEGV()]

        // When
        self.metricMonitor!.didReceive(payloads)
        // Delay 2 seconds more to test DiagnosticPayload.deserialize()
        // Delay another 5 seconds more to test beacon submission
        Thread.sleep(forTimeInterval: 10)

        // Then
        // Diagnostic files are saved in cache directory
        // After diagnostic beacon is submitted, file is deleted
        XCTAssertEqual(metricMonitor?.processedFiles.count, 0)
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertFalse(fileExist!)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_didReceive_pickASafeFile() {
        // Given
        let payloads = [MXCrashDiagnosticMock_forCrashSIGABRT()]

        // Make sure diagnostic dir is created before usage
        _ = MetricMonitor.getDiagnosticDir(createIfNotExist: true)
        // Inject an invalid diagnostic file into cache dir
        // so as to trigger test of pickASafeFile() negative case
        let fileTime = Calendar.current.date(byAdding: .day, value: -(maxDaysToKeepCrashLog+1), to: Date())!
        let fileName = String(fileTime.millisecondsSince1970)
        let fileURL = MetricMonitor.getDiagnosticDirURLName()!.appendingPathComponent(fileName)
        do {
            try "old diagnostic file".write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {}
        // Make sure above file exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // When
        self.metricMonitor!.symOp = SymbolicationOperation(metricMonitor: self.metricMonitor!)
        let cancelled = self.metricMonitor!.cancelDiagnosticReporting()
        // Then
        XCTAssertTrue(cancelled)

        // When
        self.metricMonitor!.didReceive(payloads)
        // Delay 2 seconds more to test DiagnosticPayload.deserialize()
        // Delay another 5 seconds more to test beacon submission
        Thread.sleep(forTimeInterval: 10)

        // Then
        // Invalid file is deleted immediately
        // The new diagnostic file is also deleted
        XCTAssertEqual(metricMonitor?.processedFiles.count, 0)
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertFalse(fileExist!)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_convertDiagnosticsToBeacons() {
        // Given
        // Make sure diagnostic dir is created before usage
        _ = MetricMonitor.getDiagnosticDir(createIfNotExist: true)
        // Inject a new diagnostic file into cache dir
        let fileTime = Calendar.current.date(byAdding: .second, value: 0, to: Date())!
        let fileName = String(fileTime.millisecondsSince1970)
        let fileURL = MetricMonitor.getDiagnosticDirURLName()!.appendingPathComponent(fileName)
        do {
            try "too new diagnostic file".write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {}
        // Make sure above file exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // When
        self.metricMonitor!.symOp = SymbolicationOperation(metricMonitor: self.metricMonitor!)
        let cancelled = self.metricMonitor!.cancelDiagnosticReporting()
        XCTAssertTrue(cancelled)

        self.metricMonitor!.convertDiagnosticsToBeacons()
        // wait to let symbolicateQueue start picking up the file
        Thread.sleep(forTimeInterval: 1)

        // Then
        // There must be 1 diagnostic file in cache directory
        // File is too new to be symbolicated immediately
        XCTAssertEqual(metricMonitor?.processedFiles.count, 0)
        let fileExist = MetricMonitor.diagnosticFileExistInDir()
        XCTAssertNotEqual(fileExist, nil)
        XCTAssertTrue(fileExist!)
    }

    @available(iOS 14.0, macOS 12.0, *)
    func test_describeMXDiagnosticPayloads() {
        // Given
        let payloads = [MXDiagnosticPayloadMockAll()]

        // When
        let payloadStr = self.metricMonitor!.describeMXDiagnosticPayloads(payloads)

        // Then
        XCTAssertNotEqual(payloadStr, nil)
    }
}
