//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent
import SDWebImageWebPCoder

@available(iOS 13.0, *)
internal class StagingManager {
    private enum Constants {
        static let cacheDirectoryName = "instana-sessionreplay-staging"
        static let userEventsDirectoryName = "userEvents"
        static let imageBeaconsDirectoryName = "imageBeacons"
    }

    let config: InstanaSessionReplayConfig
    var frustrationTapDetector: FrustrationTapDetector = FrustrationTapDetector()
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.instana.ios.agent.sessionreplay.staging", qos: .utility)

    private(set) var stagingDirectoryURL: URL // temporary directory


    /**
     * Cleanup interval (60 seconds in milliseconds).
     * Cleanup runs at most once per interval.
     */
    private let cleanupInterval: Instana.Types.Milliseconds = 60 * 1000 // 1 minute
    /**
     * Current buffer size in bytes.
     * Maintained incrementally to avoid overwhelming file storage usage
     */
//    private var currentBufferSize: Int = 0
    /**
     * Cleanup interval (60 seconds in milliseconds).
     * Cleanup runs at most once per interval.
     */
    var lastCleanupTime: Instana.Types.Milliseconds = 0

    init(config: InstanaSessionReplayConfig, fileManager: FileManager = .default) throws {
        self.config = config
        self.fileManager = fileManager
        self.stagingDirectoryURL = try StagingManager.createStagingDirectory(fileManager: fileManager)
        try clearAll()
    }

    static func createStagingDirectory(fileManager: FileManager = .default) throws -> URL {
        let stagingDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(Constants.cacheDirectoryName, isDirectory: true)

        if !fileManager.fileExists(atPath: stagingDirectoryURL.path) {
            try fileManager.createDirectory(at: stagingDirectoryURL, withIntermediateDirectories: true)
        }

        return stagingDirectoryURL
    }

    func clearAll() throws {
        let contents = try fileManager.contentsOfDirectory(at: stagingDirectoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles])
        for itemURL in contents {
            try fileManager.removeItem(at: itemURL)
        }
        lastCleanupTime = 0
    }

    static func cacheDirectoryName() -> String {
        Constants.cacheDirectoryName
    }

    func stageUserEvent(timestamp: Instana.Types.Milliseconds,
                         eventType: UserActionEnum,
                         eventValue: String? = nil,
                         eventValueKey: String? = nil,
                         viewClassName: String? = nil,
                         viewId: String? = nil,
                         coordinates: [[Int]] = []) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if lastCleanupTime == 0 {
                lastCleanupTime = Date().millisecondsSince1970
            }
            // Not provide coordinates since backend not process them now
            let beacon = UserEventBeacon(timestamp: timestamp,
                                         eventType: eventType.rawValue,
                                         eventValue: eventValue,
                                         eventValueKey: eventValueKey,
                                         viewClassName: viewClassName,
                                         viewId: viewId)
            if self.config.bufferDataLocally() {
                do {
                    let userEventsDirectoryURL = try self.ensureSubdirectory(named: Constants.userEventsDirectoryName)
                    let beaconFileURL = userEventsDirectoryURL.appendingPathComponent("\(timestamp)")
                    let beaconData = try JSONEncoder().encode(beacon)
                    try beaconData.write(to: beaconFileURL, options: .atomic)

                    try self.purgeFilesAsNeeded()
                } catch {
                    Instana.log("Failed to stage user event beacon locally: \(error)", level: .warning)
                }
            } else {
                Instana.reportUserEventDetails(beacon: beacon)
            }

            if eventType == UserActionEnum.tap {
                guard let lastCoord = coordinates.last else { return }
                frustrationTapDetector.checkRageTap(stagingManager: self,
                                                    timestamp: timestamp,
                                                    viewClassName: viewClassName,
                                                    viewId: viewId,
                                                    coordinates: lastCoord)
            }

        }
    }

    func stageScreenshot(timestamp: Instana.Types.Milliseconds, beacon: ImageBeacon) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if lastCleanupTime == 0 {
                lastCleanupTime = Date().millisecondsSince1970
            }
            if self.config.bufferDataLocally() {
                do {
                    // write to imageBeaconsDirectoryName directory
                    let imageBeaconsDirectoryURL = try self.ensureSubdirectory(named: Constants.imageBeaconsDirectoryName)
                    let beaconFileURL = imageBeaconsDirectoryURL.appendingPathComponent("\(timestamp)")
                    let beaconData = try JSONEncoder().encode(beacon)
                    try beaconData.write(to: beaconFileURL, options: .atomic)

                    try self.purgeFilesAsNeeded()
                } catch {
                    Instana.log("Failed to stage screenshot beacon locally: \(error)", level: .warning)
                }
            } else {
                Instana.reportImage(imageBeacons: [beacon])
            }
        }
    }

    func flushSessionReplayData() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let cutoffTime = self.config.calcCutoffTime()
            flushUserEventBeaconsUnsafe(cutoffTime: cutoffTime)
            flushImageBeaconsUnsafe(cutoffTime: cutoffTime)
        }
    }

    private func flushUserEventBeaconsUnsafe(cutoffTime: Instana.Types.Milliseconds) {
        defer {
            do {
                try self.clearSubdirectory(named: Constants.userEventsDirectoryName)
            } catch {
                Instana.log("Failed to cleanup user event staging directory: \(error)", level: .warning)
            }
        }

        do {
            let userEventsDirectoryURL = try self.ensureSubdirectory(named: Constants.userEventsDirectoryName)
            let beaconFileURLs = try self.fileManager.contentsOfDirectory(at: userEventsDirectoryURL,
                                                                         includingPropertiesForKeys: nil,
                                                                         options: [.skipsHiddenFiles])
            for beaconFileURL in beaconFileURLs {
                let beaconData = try Data(contentsOf: beaconFileURL)
                let beacon = try JSONDecoder().decode(UserEventBeacon.self, from: beaconData)
                if beacon.timestamp >= cutoffTime {
                    Instana.reportUserEventDetails(beacon: beacon)
                }
            }
        } catch {
            Instana.log("Failed to flush staged user event beacons: \(error)", level: .warning)
        }
    }

    private func flushImageBeaconsUnsafe(cutoffTime: Instana.Types.Milliseconds) {
        defer {
            do {
                try self.clearImageStagingDirectories()
            } catch {
                Instana.log("Failed to cleanup image staging directories: \(error)", level: .warning)
            }
        }

        do {
            // read in image beacons
            let imageBeaconsDirectoryURL = try self.ensureSubdirectory(named: Constants.imageBeaconsDirectoryName)
            let beaconFileURLs = try self.fileManager.contentsOfDirectory(at: imageBeaconsDirectoryURL,
                                                                         includingPropertiesForKeys: nil,
                                                                         options: [.skipsHiddenFiles])
            // image beacons (imageId) referenced by later beacons
            var oldImages: [String: Data] = [:] //imageId:imageData
            // image beacons reference previous beacons (by imageId)
            var partialBeacons: [ImageBeacon] = []
            // image beacons to be transmitted to server
            var imageBeacons: [ImageBeacon] = []
            for beaconFileURL in beaconFileURLs {
                let beaconData = try Data(contentsOf: beaconFileURL)
                let beacon = try JSONDecoder().decode(ImageBeacon.self, from: beaconData)
                if beacon.ti >= cutoffTime {
                    if beacon.img == nil {
                        // beacon reference previous beacon's image
                        partialBeacons.append(beacon)
                    } else {
                        imageBeacons.append(beacon)
                    }
                } else { // old beacon to be purged
                    // image might be referenced by later beacons
                    if let imgage = beacon.img, let imageId = beacon.meta["imageId"] {
                        oldImages[imageId] = imgage
                    }
                }
            }

            // partial beacons that reference previous images
            // todo: multi partialBeacon with same imageId check!!!
            for var partialBeacon in partialBeacons {
                if let partialBeaconImageId = partialBeacon.meta["imageId"] {
                    guard let stagingEntry = oldImages[partialBeaconImageId] else { continue }
                    partialBeacon.img = stagingEntry
                    imageBeacons.append(partialBeacon)
                }
            }
            if imageBeacons.count > 0 {
                Instana.reportImage(imageBeacons: imageBeacons)
            }
        } catch {
            Instana.log("Failed to flush staged screenshot beacons: \(error)", level: .warning)
        }
    }

    private func purgeFilesAsNeeded() throws {
        // shouldRunCleanup?
        let now = Date().millisecondsSince1970
        let shouldRun = (now - lastCleanupTime) > cleanupInterval
        guard shouldRun else { return }

        lastCleanupTime = now
        // enforceLimits
        let cutoffTime = config.calcCutoffTime()
        try purgeExpiredImageFiles(inSubdirectoryNamed: Constants.imageBeaconsDirectoryName, cutoffTimestamp: cutoffTime)
        try purgeExpiredFiles(inSubdirectoryNamed: Constants.userEventsDirectoryName, cutoffTimestamp: cutoffTime)
    }

    private func purgeExpiredImageFiles(inSubdirectoryNamed name: String,
                                        cutoffTimestamp: Instana.Types.Milliseconds) throws {
        let directoryURL = try ensureSubdirectory(named: name)
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles])
        var referencedImageIds: [String: Data] = [:]
        var beaconsReferenceOldImage: [ImageBeacon] = []
        let placeholderData: Data = Data([0x01])

        for fileURL in fileURLs {
            let beaconData = try Data(contentsOf: fileURL)
            let beacon = try JSONDecoder().decode(ImageBeacon.self, from: beaconData)
            if beacon.img == nil, beacon.ti >= cutoffTimestamp, let imageId = beacon.meta["imageId"] {
                referencedImageIds[imageId] = placeholderData
                beaconsReferenceOldImage.append(beacon)
            }
        }

        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
            guard let timestamp = Instana.Types.Milliseconds(fileName), timestamp < cutoffTimestamp else {
                continue
            }

            let beaconData = try Data(contentsOf: fileURL)
            let beacon = try JSONDecoder().decode(ImageBeacon.self, from: beaconData)
            let imageId = beacon.meta["imageId"]

            if beacon.img != nil, let imageId, referencedImageIds[imageId] == placeholderData {
                // If this old file contains an image that is referenced by a newer beacon,
                // copy its data and assign to later image beacons.
                referencedImageIds[imageId] = beacon.img
            }
            try fileManager.removeItem(at: fileURL)
        }

        // update retained beacons that reference purged images
        for var beacon in beaconsReferenceOldImage {
            do {
                if let imageId = beacon.meta["imageId"] {
                    beacon.img = referencedImageIds[imageId]
                }
                // write to imageBeaconsDirectoryName directory
                let imageBeaconsDirectoryURL = try self.ensureSubdirectory(named: Constants.imageBeaconsDirectoryName)
                let beaconFileURL = imageBeaconsDirectoryURL.appendingPathComponent("\(beacon.ti)")
                let beaconData = try JSONEncoder().encode(beacon)
                try beaconData.write(to: beaconFileURL, options: .atomic)
            } catch {
                Instana.log("Failed to update image beacon locally: \(error)", level: .warning)
            }
        }
    }

    private func purgeExpiredFiles(inSubdirectoryNamed name: String,
                                   cutoffTimestamp: Instana.Types.Milliseconds) throws {
        let directoryURL = try ensureSubdirectory(named: name)
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles])

        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
            guard let timestamp = Instana.Types.Milliseconds(fileName), timestamp >= cutoffTimestamp else {
                continue
            }
            try fileManager.removeItem(at: fileURL)
        }
    }

    private func ensureSubdirectory(named name: String) throws -> URL {
        let directoryURL = stagingDirectoryURL.appendingPathComponent(name, isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        return directoryURL
    }

    private func clearImageStagingDirectories() throws {
        try clearSubdirectory(named: Constants.imageBeaconsDirectoryName)
    }

    private func clearSubdirectory(named name: String) throws {
        let directoryURL = try ensureSubdirectory(named: name)
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles])
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
