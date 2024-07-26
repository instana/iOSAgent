//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
    import ImageTracker
#endif

struct DiagnosticSymbolicator {
    let callStackPerThread: Bool?
    let threads: [DiagnosticThread]

    init(callStackTree: CallStackTree) {
        callStackPerThread = callStackTree.callStackPerThread
        threads = callStackTree.callStacks
    }

    // Either symbolicate (when needToSymbolicate is true)
    // or simply format output in a way similiar to crash report
    func symbolicate(operation: SymbolicationOperation, diagPayload: DiagnosticPayload,
                     needToSymbolicate: Bool) -> String? {
        var binaryImages = [BinaryImage]()
        var setUUIDs = Set<String>() // set of image UUID to speed up binary image search

        for idx in 0 ..< threads.count {
            if operation.isCancelled { return nil }

            let framesForThread = threads[idx].frameArray
            var formatted = [SymbolicationFrame?]()
            formatted.reserveCapacity(framesForThread.count)
            for frame in framesForThread {
                guard frame.binaryUUID != nil,
                    frame.offsetIntoBinaryTextSegment != nil,
                    frame.binaryName != nil,
                    frame.address != nil
                else {
                    formatted.append(nil)
                    continue
                }

                var oneBii: BinaryImage?
                let strUUID = frame.binaryUUID!.uuidString.lowercased()
                if !setUUIDs.contains(strUUID) {
                    setUUIDs.insert(strUUID)
                    let filteredUUID = strUUID.filter { $0 != "-" }
                    oneBii = BinaryImage(loadAddress: UInt(frame.offsetIntoBinaryTextSegment!),
                                         binaryName: frame.binaryName!,
                                         binaryUUID: filteredUUID)
                }

                let symFrame = frame.symbolicationFrame()
                var dlInfo: DynamicLibraryInfo?
                if needToSymbolicate {
                    dlInfo = symbolicate(address: frame.address!, symFrame: symFrame)
                }
                if oneBii != nil, dlInfo != nil {
                    oneBii!.arch = dlInfo!.architecture ?? "<unknown>"
                    oneBii!.fullPath = dlInfo!.path ?? ""
                    oneBii!.maxAddress = dlInfo!.size + oneBii!.loadAddress - 1
                }
                formatted.append(symFrame)
                if oneBii != nil {
                    binaryImages.append(oneBii!) // keep natural order
                }
            }
            threads[idx].formatted = formatted
        }
        return outputSymbolicatedThreads(operation: operation,
                                         diagPayload: diagPayload,
                                         binaryImages: binaryImages,
                                         needToSymbolicate: needToSymbolicate)
    }

    func outputSymbolicatedThreads(operation: SymbolicationOperation,
                                   diagPayload: DiagnosticPayload,
                                   binaryImages: [BinaryImage],
                                   needToSymbolicate: Bool) -> String? {
        let stackTrace = StackTrace()

        let headers = outputHeaderSection(operation: operation, diagPayload: diagPayload)
        stackTrace.setHeader(stHeaders: headers)

        // Binary Images section
        // process before Threads section so as to build indices of binary images for frames to reference
        var dictUUIDs: [String: Int] = [:]
        dictUUIDs.reserveCapacity(binaryImages.count)
        binaryImages.forEach { bii in
            let mAddr = (bii.maxAddress == 0 ? (needToSymbolicate ? "<unknown>  " : "")
                : String(format: "0x%llx", bii.maxAddress))

            stackTrace.appendBinaryImage(startAddr: String(bii.loadAddress),
                                         endAddr: needToSymbolicate ? mAddr : nil,
                                         name: bii.binaryName,
                                         arch: needToSymbolicate ? bii.arch : nil,
                                         uuid: bii.binaryUUID,
                                         path: needToSymbolicate ? bii.fullPath : nil)
            dictUUIDs[bii.binaryUUID] = stackTrace.binaryImages.count - 1
        }

        // Threads section
        for idx in 0 ..< threads.count {
            if operation.isCancelled { return nil }

            var state: String?
            if threads[idx].threadAttributed != nil, threads[idx].threadAttributed! {
                state = "attributed"
            }

            let stThread = StThread(state: state)

            let framesForThread = threads[idx].frameArray
            for fdx in 0 ..< framesForThread.count {
                let frame = threads[idx].frameArray[fdx]

                guard frame.binaryUUID != nil,
                    frame.offsetIntoBinaryTextSegment != nil,
                    frame.binaryName != nil,
                    frame.address != nil
                else {
                    continue
                }

                var stSymbol: String?
                var stOffset: String?
                let symFrame = threads[idx].formatted![fdx]
                if symFrame != nil, symFrame!.symbol != nil {
                    if symFrame!.symbol!.demangledSymbol != nil {
                        stSymbol = symFrame!.symbol!.demangledSymbol!
                    } else {
                        stSymbol = symFrame!.symbol!.symbol
                    }
                    if symFrame!.symbol!.offset != nil {
                        stOffset = String(symFrame!.symbol!.offset!)
                    }
                }
                var sampleCount: Int?
                if frame.sampleCount != nil, frame.sampleCount! != 1 {
                    sampleCount = frame.sampleCount!
                }
                let filteredUUID = frame.binaryUUID!.uuidString.lowercased().filter { $0 != "-" }
                stThread.appendFrame(index: dictUUIDs[filteredUUID] ?? -1,
                                     name: frame.binaryName!,
                                     address: String(format: "0x%llx", frame.address!),
                                     offsetIntoBinaryTextSegment: String(frame.offsetIntoBinaryTextSegment!),
                                     sampleCount: sampleCount,
                                     symbol: stSymbol,
                                     symbolOffset: stOffset)
            }
            stackTrace.appendThread(stThread: stThread)
        }
        return stackTrace.serialize()
    }

    func outputHeaderSection(operation: SymbolicationOperation, diagPayload: DiagnosticPayload) -> [StHeader] {
        var stHeaders = [StHeader]()

        if diagPayload.bundleIdentifier != nil {
            stHeaders.append(StHeader(key: "Identifier", value: diagPayload.bundleIdentifier!))
        }
        if diagPayload.appBuildVersion != nil, diagPayload.appVersion != nil {
            let ver = String(format: "%@(%@)", diagPayload.appVersion!, diagPayload.appBuildVersion!)
            stHeaders.append(StHeader(key: "Version", value: ver))
        }
        if diagPayload.deviceType != nil {
            stHeaders.append(StHeader(key: "Hardware Model", value: diagPayload.deviceType!))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let timeStr = formatter.string(from: Date(timeIntervalSince1970: Double(diagPayload.crashTime) / 1000.0))
        stHeaders.append(StHeader(key: "Date/Time", value: timeStr))

        let launchTime = formatter.string(from: diagPayload.crashSession.startTime)
        stHeaders.append(StHeader(key: "Launch Time", value: launchTime))

        if diagPayload.osVersion != nil {
            stHeaders.append(StHeader(key: "OS Version", value: diagPayload.osVersion!))
        }

        if diagPayload.platformArchitecture != nil {
            stHeaders.append(StHeader(key: "Platform Architecture", value: diagPayload.platformArchitecture!))
        }

        // crash
        stHeaders.append(contentsOf: getCrashHeader(operation: operation, diagPayload: diagPayload))
        // cpu
        if diagPayload.totalCPUTime != nil {
            stHeaders.append(StHeader(key: "Total CPU Time", value: diagPayload.totalCPUTime!))
        }
        if diagPayload.totalSampledTime != nil {
            stHeaders.append(StHeader(key: "Total Sampled Time", value: diagPayload.totalSampledTime!))
        }
        // disk write
        if diagPayload.writesCaused != nil {
            stHeaders.append(StHeader(key: "Writes Caused", value: diagPayload.writesCaused!))
        }
        // hang
        if diagPayload.hangDuration != nil {
            stHeaders.append(StHeader(key: "Hang Duration", value: diagPayload.hangDuration!))
        }
        // app launch
        if diagPayload.launchDuration != nil {
            stHeaders.append(StHeader(key: "Launch Duration", value: diagPayload.launchDuration!))
        }

        if let triggeredByThread = getTriggeredByThread(diagPayload: diagPayload) {
            stHeaders.append(StHeader(key: "Triggered by Thread", value: triggeredByThread))
        }

        return stHeaders
    }

    func getCrashHeader(operation: SymbolicationOperation, diagPayload: DiagnosticPayload) -> [StHeader] {
        var crashHeaders = [StHeader]()

        let exceptionTypeDisplay = DiagnosticPayload.getMachExceptionTypeDisplayName(
            exceptionType: diagPayload.exceptionType as? NSNumber)
        if exceptionTypeDisplay != nil {
            crashHeaders.append(StHeader(key: "Exception Type", value: exceptionTypeDisplay!))
        }

        var exceptionCodeDisplay = DiagnosticPayload.getMachExceptionCodeDisplayName(
            exceptionType: diagPayload.exceptionType as? NSNumber,
            exceptionCode: diagPayload.exceptionCode as? NSNumber)
        if exceptionCodeDisplay != nil {
            if exceptionCodeDisplay != String(diagPayload.exceptionCode!) {
                exceptionCodeDisplay! += " \(diagPayload.exceptionCode!)"
            }
            crashHeaders.append(StHeader(key: "Exception Code", value: exceptionCodeDisplay!))
        }

        let signal = DiagnosticPayload.getSignalName(signal: diagPayload.signal as? NSNumber)
        if signal != nil {
            crashHeaders.append(StHeader(key: "signal", value: signal!))
        }

        if diagPayload.terminationReason != nil {
            crashHeaders.append(StHeader(key: "Termination Reason", value: diagPayload.terminationReason!))
        }
        if diagPayload.virtualMemoryRegionInfo != nil {
            crashHeaders.append(StHeader(key: "Virtual Memory Region Info", value: diagPayload.virtualMemoryRegionInfo!))
        }
        return crashHeaders
    }

    func getTriggeredByThread(diagPayload: DiagnosticPayload) -> String? {
        for idx in 0 ..< threads.count {
            if threads[idx].threadAttributed != nil, threads[idx].threadAttributed! {
                return String(idx)
            }
        }
        return nil
    }
}

extension DiagnosticSymbolicator {
    public func symbolicate(address: UInt, symFrame: SymbolicationFrame?) -> DynamicLibraryInfo? {
        guard let allImages = ImageTracker.binaryImagesDict else { return nil }
        guard let symFrame = symFrame, let loadedImage = allImages[symFrame.binaryUUID.uuidString],
            let imageDetail = loadedImage as? ImageDetail else {
            return nil
        }

        // meaning for offsetIntoBinaryTextSegment and address are different between arm64 and arm64e
        var addr: UInt
        if #available(macOS 13, iOS 16, *) {
            addr = UInt(imageDetail.baseAddress) + symFrame.offsetIntoBinaryTextSegment
        } else {
            addr = UInt(imageDetail.baseAddress) + address - symFrame.offsetIntoBinaryTextSegment
        }

        guard let dlInfo = DynamicLibraryInfo(imageInMemory: imageDetail.inMemory,
                                              address: addr,
                                              architecture: imageDetail.getArchitecture(),
                                              size: UInt(imageDetail.size),
                                              path: imageDetail.path) else {
            return nil
        }

        symFrame.symbol = dlInfo.symbolInfo
        return dlInfo
    }
}
