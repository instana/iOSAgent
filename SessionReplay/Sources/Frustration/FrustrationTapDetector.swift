//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
public final class FrustrationTapDetector: NSObject {

    private let rageTapCountThreshold: Int
    private let rageTapThresholdDistance: Int
    private let rageTapThresholdTime: Instana.Types.Milliseconds

    internal var rageTapTimestamps: [Instana.Types.Milliseconds] = []
    internal var rageTapLocations: [(Int, Int)] = []

    public init(rageTapCountThreshold: Int = 3,
                rageTapThresholdDistance: Int = 100,
                rageTapThresholdTime: Instana.Types.Milliseconds = 1400) {
        self.rageTapCountThreshold = rageTapCountThreshold
        self.rageTapThresholdDistance = rageTapThresholdDistance
        self.rageTapThresholdTime = rageTapThresholdTime
        super.init()
    }

    func checkRageTap(stagingManager: StagingManager?,
                      timestamp: Instana.Types.Milliseconds,
                      viewClassName: String?,
                      viewId: String?,
                      coordinates: [Int]) {
            let currentTime = timestamp
            let currentPointX = coordinates[0]
            let currentPointY = coordinates[1]

            rageTapTimestamps.removeAll {
                currentTime - $0 > self.rageTapThresholdTime
            }
            if rageTapLocations.count > rageTapTimestamps.count {
                rageTapLocations = Array(rageTapLocations.prefix(rageTapTimestamps.count))
            }

            rageTapTimestamps.append(currentTime)
            rageTapLocations.append((currentPointX, currentPointY))

            let allClose = rageTapLocations.allSatisfy { point in
                let dx = abs(point.0 - currentPointX)
                let dy = abs(point.1 - currentPointY)
                return dx < self.rageTapThresholdDistance && dy < self.rageTapThresholdDistance
            }

            if rageTapTimestamps.count >= rageTapCountThreshold && allClose {
                reportRageTap(stagingManager: stagingManager, timestamp: timestamp,
                              viewClassName: viewClassName, viewId: viewId, coordinates: coordinates)
                rageTapTimestamps.removeAll()
                rageTapLocations.removeAll()
            }
    }

    private func reportRageTap(stagingManager: StagingManager?,
                               timestamp: Instana.Types.Milliseconds,
                               viewClassName: String?,
                               viewId: String?,
                               coordinates: [Int]) {
        Instana.log("Rage Tap detected on \(String(describing: viewClassName)) at (\(coordinates[0]), \(coordinates[1]))", level:.debug)
        stagingManager?.stageUserEvent(timestamp: timestamp,
                                      eventType: .frustrationSignal,
                                      eventValue: FrustrationSignalValueEnum.rageTap.rawValue,
                                      eventValueKey: userActionKey_frustrationSignal,
                                      viewClassName: viewClassName,
                                      viewId: viewId,
                                      coordinates: [coordinates])

        let samplingConfig = stagingManager?.config.samplingConfig
        if stagingManager?.config.isSampled == false && samplingConfig?.isRelevantSamplingEnabled(for: RelevantSessionType.frustration) == true {
            Instana.log("Frustration signal detected - triggering relevant sampling flush (samplingPercentage: \(String(describing: samplingConfig?.samplingPercentage))%)", level:.debug)
            stagingManager?.flushSessionReplayData()
        }
    }
}
