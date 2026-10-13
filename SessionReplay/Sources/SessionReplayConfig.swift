//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent


@available(iOS 13.0, *)
@objc public class InstanaSessionReplayConfig: NSObject, NSCopying {

    @objc public var framePerSecond: Double = 1.0   // number of screenshots per second
    @objc public var maskStrategy: MaskingStrategy = .mask_all
    @objc public var maskingColor: UIColor = .black
    @objc public var enableImageCapture: Bool = true
    @objc public var hammingDistance: Int = 3   // screenshot hash sensitivity (suggest 0 to 10)
    @objc public var useFastScreenCapture: NSNumber? = false // true, false or nil
    @objc public var samplingConfig: SamplingConfig = SamplingConfig()

    var isSampled: Bool = false
    var disabledByServer: Bool = false

    @objc
    public init(framePerSecond: Double = 1.0,
                maskStrategy: MaskingStrategy = .mask_all,
                maskingColor: UIColor = .black,
                enableImageCapture: Bool = true,
                hammingDistance: Int = 3,
                samplingConfig: SamplingConfig = SamplingConfig()) {
        self.framePerSecond = framePerSecond
        self.maskStrategy = maskStrategy
        self.maskingColor = maskingColor
        self.enableImageCapture = enableImageCapture
        self.hammingDistance = hammingDistance
        self.samplingConfig = samplingConfig
        super.init()
    }

    @objc public
    override init() {
        super.init()
    }

    // NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = InstanaSessionReplayConfig(
            framePerSecond: framePerSecond,
            maskStrategy: maskStrategy,
            maskingColor: maskingColor,
            enableImageCapture: enableImageCapture,
            hammingDistance: hammingDistance,
            samplingConfig: samplingConfig.copy(with: zone) as! SamplingConfig
        )
        copy.useFastScreenCapture = useFastScreenCapture
        copy.isSampled = isSampled
        copy.disabledByServer = disabledByServer
        return copy
    }

    internal func calcCutoffTime(_ timestamp: Instana.Types.Milliseconds? = nil) -> Instana.Types.Milliseconds {
        let timestamp = timestamp ?? Date().millisecondsSince1970
        return timestamp - Instana.Types.Milliseconds(samplingConfig.maxTimeBufferMinutes * 60.0 * 1000.0)
    }

//    internal func calcCutoffSize() -> Double {
//        return samplingConfig.maxSizeBufferMb * 1000000.0 // in bytes
//    }

    internal func bufferDataLocally() -> Bool {
        return !isSampled && (samplingConfig.onDemandSamplingEnabled || samplingConfig.relevantSamplingConfig.enabled)
    }

    internal func isTrackingEnabled() -> Bool {
        if disabledByServer { return false }
        return isSampled || samplingConfig.onDemandSamplingEnabled || samplingConfig.relevantSamplingConfig.enabled
    }

    internal func getScreenshotsCaptureIntervalInSeconds() -> Double {
        return 1.0 / framePerSecond
    }

    func syncWithServerConfiguration(serverConfig: RuntimeConfiguration?) -> Bool {
        guard let serverConfig = serverConfig else { return false }

        if serverConfig.configurationTimeStamp == 0 {
            // no server side configuration
            return false
        }

        let previousDisabledByServer = disabledByServer
        disabledByServer = (serverConfig.srServerConfig == .disabled)
        return disabledByServer != previousDisabledByServer
    }
}
