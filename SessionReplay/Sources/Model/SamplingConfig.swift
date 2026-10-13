//
//  Copyright © 2026 IBM Corp. All rights reserved.
//
import Foundation

/// Config for session sampling strategies
@objcMembers
public class SamplingConfig: NSObject {
    public var samplingPercentage: Int = 100

    public var onDemandSamplingEnabled: Bool = false
    public var maxTimeBufferMinutes: Double = 3.0    // in minutes
//    public var maxSizeBufferMb: Double = 1.0  // in mega bytes

    public var relevantSamplingConfig: RelevantSamplingConfig = RelevantSamplingConfig()


    public init(samplingPercentage: Int = 100,
                onDemandSamplingEnabled: Bool = false,
                relevantSamplingConfig: RelevantSamplingConfig = RelevantSamplingConfig()) {
        precondition((0...100).contains(samplingPercentage),
                     "Sampling percentage must be between 0 and 100, got: \(samplingPercentage)")
        self.samplingPercentage = samplingPercentage
        self.onDemandSamplingEnabled = onDemandSamplingEnabled
        self.relevantSamplingConfig = relevantSamplingConfig
    }

    public override init() {
        super.init()
    }

    // NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        return SamplingConfig(
            samplingPercentage: samplingPercentage,
            onDemandSamplingEnabled: onDemandSamplingEnabled,
            relevantSamplingConfig: relevantSamplingConfig.copy(with: zone) as! RelevantSamplingConfig
        )
    }

    /**
     * Check if should report frustration
     */
    func isRelevantSamplingEnabled(for frustrationType: RelevantSessionType) -> Bool {
        return (relevantSamplingConfig.enabled &&
            relevantSamplingConfig.enableOnEventTypes.contains(frustrationType))
    }

    /**
     * Check if buffering should be enabled for this configuration.
     *
     * Buffering is enabled when percentage sampling is less than 100% AND either
     * on-demand sampling or relevant sampling is enabled.
     *
     * @return `true` if buffering should be enabled, `false` otherwise
     */
    func isBufferingEnabled() -> Bool {
        return samplingPercentage < 100 && (onDemandSamplingEnabled || relevantSamplingConfig.enabled)
    }
}
