//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
    import MetricKit
#endif
#if SWIFT_PACKAGE
    import ImageTracker
#endif

class MetricMonitor: NSObject, MXMetricManagerSubscriber {
    let session: InstanaSession
    let reporter: Reporter
    let symbolicateQueue = DispatchQueue(label: "com.instana.ios.agent.symbolication", qos: .utility)
    var symOp: SymbolicationOperation?
    var processedFiles = AtomicSet<String>()

    init(_ session: InstanaSession, reporter: Reporter) {
        self.session = session
        self.reporter = reporter
        super.init()

        subscribeCrashReporting()
    }

    ///
    /// If you call this function from a method that deallocates the object, your app might crash.
    ///
    private func subscribeCrashReporting() {
        if #available(iOS 13.0, macOS 12, *) {
            MXMetricManager.shared.add(self)
        }
    }

    func stopCrashReporting() {
        if #available(iOS 13.0, macOS 12, *) {
            MXMetricManager.shared.remove(self)
        }
    }

    func cancelDiagnosticReporting() -> Bool {
        defer {
            self.symOp = nil
        }

        guard let symOp = symOp else { return false }
        let ret = symOp.isReady || symOp.isExecuting
        symOp.cancel()
        return ret
    }

    ///
    /// Receive daily metrics.
    ///
    #if os(iOS)
        @available(iOS 13.0, *)
        public func didReceive(_ payloads: [MXMetricPayload]) {}
    #endif

    ///
    /// Receive diagnostics immediately when available.
    ///
    @available(iOS 14.0, macOS 12.0, *)
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        if !session.collectionEnabled { return }
        session.logger.add("didReceive MXDiagnosticPayload array size \(payloads.count)", level: .debug)
//        #if DEBUG
//            print(describeMXDiagnosticPayloads(payloads))
//        #endif

        var fileNameTime = Date().millisecondsSince1970
        payloads.forEach { payload in
            // Ignore crash payload that is too old or impossible to symbolicate
            if session.previousSession != nil, PreviousSession.isCrashTimeWithinRange(payload.timeStampEnd) {
                // unique id that connects all crashes within same payload array
                let crashGroupID = UUID()
                let diagPlds = DiagnosticPayload.createDiagnosticPayloads(
                    crashSession: session.previousSession!,
                    crashGroupID: crashGroupID,
                    payload: payload)
                serializeDiagnosticPayloads(payloads: diagPlds, fnTime: &fileNameTime)
            }
        }
        Instana.current?.session.logger.add("Done saving diagnostic payloads. Delay 2 seconds before symbolication", level: .debug)
        symbolicateQueue.asyncAfter(deadline: .now() + 2) { [weak self] in
            Instana.current?.session.logger.add("After 2 seconds delay, about to symbolicate all diagnostics", level: .debug)
            self?.convertDiagnosticsToBeacons()
        }
    }

    func serializeDiagnosticPayloads(payloads: [DiagnosticPayload], fnTime: inout Instana.Types.Milliseconds) {
        guard let dir = Self.getDiagnosticDir(createIfNotExist: true) else { return }

        let step = 5 // 5 milliseconds as a max step to search for next available file name
        payloads.forEach { payload in
            var foundName = false
            var fileURL = dir.appendingPathComponent(String(fnTime))
            for _ in 0 ..< 20 {
                // make sure fileURL is not being taken by another diagnostic
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    fnTime += Int64(step)
                    fileURL = dir.appendingPathComponent(String(fnTime))
                } else {
                    foundName = true
                    break
                }
            }
            if foundName {
                payload.serialize(fileURL: fileURL)
            }
            fnTime += Int64(step)
        }
    }

    func convertDiagnosticsToBeacons() {
        if !session.collectionEnabled { return }

        symbolicateQueue.async { [weak self] in
            let diagFilesExist = Self.diagnosticFileExistInDir(createIfNotExist: true)
            if diagFilesExist == nil { return } // Error occurred
            // No diagnostic files at this moment
            if !diagFilesExist! {
                Instana.current?.session.logger.add("\(#function) No diagnostic files to convert to beacon", level: .debug)
                return
            }

            guard self != nil else { return }
            if self!.symOp == nil {
                Instana.current?.session.logger.add("\(#function) Create new operation", level: .debug)
            } else if self!.symOp!.isCancelled || self!.symOp!.isFinished {
                Instana.current?.session.logger.add("\(#function) Previous operation done. Create new one.", level: .debug)
            } else {
                // Previous operation is not done, let it pick up the new files
                Instana.current?.session.logger.add("\(#function) Previous operation going on. Bail out!", level: .debug)
                return
            }
            self!.symOp = SymbolicationOperation(metricMonitor: self)

            let newlyStarted = ImageTracker.startTrackingDyldImages()
            // If newly start tracking binary images, wait seconds to let images registered first
            let delay: DispatchTime = newlyStarted ? (.now() + 5) : .now()
            self?.symbolicateQueue.asyncAfter(deadline: delay) { [weak self] in
                guard self != nil else { return }
                if self?.symOp != nil, self!.symOp!.isReady {
                    self?.symOp!.start()
                }
            }
        }
    }

    @available(iOS 14.0, macOS 12.0, *)
    func describeMXDiagnosticPayloads(_ payloads: [MXDiagnosticPayload]) -> String {
        var all = [String]()
        payloads.forEach {
            let jsonData = $0.jsonRepresentation()
            all.append(String(decoding: jsonData, as: UTF8.self))
        }
        return "[\n" + all.joined(separator: ",\n") + "\n]"
    }

    static func getDiagnosticDir(createIfNotExist: Bool = false) -> URL? {
        guard let dir = Self.getDiagnosticDirURLName() else { return nil }
        do {
            if createIfNotExist {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        } catch {
            Instana.current?.session.logger.add("\(#function) \(error), createDir=\(createIfNotExist)", level: .error)
            return nil
        }
        return dir
    }

    static func getDiagnosticDirURLName() -> URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cacheDirectory.appendingPathComponent("diagnostics")
    }

    // for unit test cleanup
    @discardableResult static func deleteDiagnosticFiles(includeDir: Bool) -> Bool? {
        guard let dir = Self.getDiagnosticDirURLName() else { return nil }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            try files.forEach {
                try FileManager.default.removeItem(at: $0)
            }
            if includeDir {
                try FileManager.default.removeItem(at: dir)
            }
            return true
        } catch {
            Instana.current?.session.logger.add("\(#function) \(error)", level: .error)
            return nil
        }
    }

    static func diagnosticFileExistInDir(createIfNotExist: Bool = false,
                                         function: String = #function) -> Bool? {
        guard let dir = Self.getDiagnosticDirURLName() else { return nil }
        do {
            // First make sure diagnostic dir exist
            var isDir: ObjCBool = false
            let dirExist = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
            if !dirExist {
                if createIfNotExist {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                return false
            }

            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            return files.count > 0
        } catch {
            let nsError = (error as NSError)
            Instana.current?.session.logger.add("in \(function) errorCode=\(nsError.code) \(error)", level: .error)
            return nil
        }
    }
}
