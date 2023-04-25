//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
    import ImageTracker
#endif

class SymbolicationOperation: Operation {
    weak var metricMonitor: MetricMonitor?

    init(metricMonitor: MetricMonitor?) {
        self.metricMonitor = metricMonitor
        super.init()
    }

    override func main() {
        var round = 0
        while true { // loop for all files ready to be beaconized
            if round > 0 {
                // Give other threads more time
                Thread.sleep(forTimeInterval: 5)
            }
            round += 1
            if isCancelled { return }

            guard let fileURL = chooseFileToSymbolicate() else { return }
            if let diagPayload = DiagnosticPayload.deserialize(fileURL: fileURL) {
                formatPayload(diagPayload: diagPayload, needToSymbolicate: diagPayload.canSymbolicate())
            }
        }
    }

    func generateDiagnosticBeacon(diagPayload: DiagnosticPayload, formatted: String?, fileURL: URL) {
        if isCancelled { return }

        let beacon = DiagnosticBeacon.createDiagnosticBeacon(payload: diagPayload, formatted: formatted)
        metricMonitor?.reporter.submit(beacon) { [weak self] succeeded in
            if succeeded {
                if diagPayload.deletePayloadFile() {
                    self?.metricMonitor?.processedFiles.remove(fileURL.lastPathComponent)
                    Instana.current?.session.logger.add("Diagnostic beacon from \(fileURL) is submitted successfully", level: .debug)
                }
            } else {
                var msg = "Diagnostic beacon reporting failed"
                #if DEBUG
                    msg += " for file \(fileURL)"
                #endif
                Instana.current?.session.logger.add(msg, level: .error)
            }
        }
    }

    func formatPayload(diagPayload: DiagnosticPayload, needToSymbolicate: Bool) {
        if isCancelled { return }

        let param = needToSymbolicate ? "symbolicating" : "formatting"
        var msg = "Start \(param) diagnostic payload \(diagPayload.fileURL!)"
        Instana.current?.session.logger.add(msg, level: .debug)

        var formatted: String?
        if diagPayload.callStackTree != nil {
            let symBolicator = DiagnosticSymbolicator(callStackTree: diagPayload.callStackTree!)

            guard metricMonitor != nil else { return }
            formatted = symBolicator.symbolicate(operation: self,
                                                 diagPayload: diagPayload,
                                                 needToSymbolicate: needToSymbolicate)
            if formatted != nil {
//                #if DEBUG
//                    print(formatted!)
//                #endif
                if needToSymbolicate {
                    diagPayload.isSymbolicated = true
                }
            }
        }

        msg = "Diagnostic payload from \(diagPayload.fileURL!) is \(param) successfully"
        Instana.current?.session.logger.add(msg, level: .debug)

        generateDiagnosticBeacon(diagPayload: diagPayload,
                                 formatted: formatted,
                                 fileURL: diagPayload.fileURL!)
    }

    func chooseFileToSymbolicate() -> URL? {
        guard let dir = MetricMonitor.getDiagnosticDir() else { return nil }
        do {
            var files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            guard let metricMonitor = metricMonitor else { return nil }
            files = files.filter {
                !metricMonitor.processedFiles.contains($0.lastPathComponent)
            }
            if files.count == 0 { return nil }
            return pickASafeFile(filePaths: files)
        } catch {
            Instana.current?.session.logger.add("\(#function) error \(error)", level: .error)
        }
        return nil
    }

    func pickASafeFile(filePaths: [URL]) -> URL? {
        guard let dirPayload = MetricMonitor.getDiagnosticDir() else { return nil }
        // Pick the oldest file to symbolicate
        var numDeletedFiles = 0
        let allFiles = filePaths.map {
            $0.lastPathComponent
        }.sorted(by: <)
        for fileName in allFiles {
            let numFileName = Int64(fileName)
            if numFileName == nil || !PreviousSession.isCrashTimeWithinRange(numFileName!) {
                // Invalid file name or file is too old, just delete it
                numDeletedFiles += 1
                do {
                    try FileManager.default.removeItem(at: dirPayload.appendingPathComponent(fileName))
                } catch {
                    Instana.current?.session.logger.add("Error \(error) deleting old file \(fileName)", level: .error)
                }
            } else {
                break
            }
        }

        guard numDeletedFiles < filePaths.count else { return nil }

        let idx = numDeletedFiles
        let pickedFileURL = dirPayload.appendingPathComponent(String(allFiles[idx]))

        if idx < filePaths.count - 1 {
            metricMonitor?.processedFiles.insert(String(allFiles[idx]))
            return pickedFileURL
        }
        // Only one file available, make sure it's not being written at this moment

        guard let fileCreationTime = Int64(allFiles[idx]) else { return nil }
        let currentTime = Date().millisecondsSince1970
        if (currentTime - fileCreationTime) >= 2000 {
            // Over 2 seconds after file was created, safe to read
            metricMonitor?.processedFiles.insert(String(allFiles[idx]))
            return pickedFileURL
        }
        // File is too new, not symbolicate at this moment.
        // Worst case it gets symbolicated next time the app launches.
        Instana.current?.session.logger.add("\(pickedFileURL) is newly created, might still be written now. Skip symbolication", level: .debug)
        return nil
    }
}
