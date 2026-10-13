//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

/// Configuration for relevant sampling strategy.
///
/// Relevant sampling automatically captures and flushes session replay data when specific
/// critical events occur, ensuring important user experiences are recorded regardless of
/// percentage sampling configuration.
///
/// When enabled, this strategy:
/// - Automatically enables buffering of the last MAX_TIME_BUFFER_MINUTES minutes of session data
/// - Monitors for configured relevant events (frustration)
/// - Automatically flushes buffered data when relevant events are detected
/// - Also allows manual flushing via `flushSessionReplayData()` API
///
/// Important Constraints:
/// - Only available when `samplingPercentage < 100` in `SamplingConfig`
/// - When enabled, buffering is automatic (no need to enable on-demand sampling separately)
///
/// - Parameters:
///   - enabled: Whether relevant sampling is enabled. Default is `false`.
///   - enableOnEventTypes: Set of event types that trigger automatic data flushing.
///     Default is `[]`.
///
/// - SeeAlso: `RelevantSessionType`, `SamplingConfig`

@objcMembers
public class RelevantSamplingConfig: NSObject, NSCopying {

    let enabled: Bool
    let enableOnEventTypes: Set<RelevantSessionType>

    /// Memberwise initializer with validation
    public init(
        enabled: Bool = false,
        enableOnEventTypes: Set<RelevantSessionType> = []
    ) {
        if enabled && enableOnEventTypes.isEmpty {
            preconditionFailure("enableOnEventTypes must not be empty when relevant sampling is enabled")
        }

        self.enabled = enabled
        self.enableOnEventTypes = enableOnEventTypes
    }

    /// Objective-C convenience initializer
    /// - Parameters:
    ///   - enabled: Whether relevant sampling is enabled
    ///   - enableOnEventTypes: NSSet of NSNumber wrapping RelevantSessionType raw values
    @objc(initWithEnabled:enableOnEventTypes:)
    public convenience init(enabled: Bool, enableOnEventTypes: NSSet) {
        // Map NSSet<NSNumber *> to Set<RelevantSessionType>
        let numbers = enableOnEventTypes.compactMap { $0 as? NSNumber }
        let types = Set(numbers.compactMap { RelevantSessionType(rawValue: $0.intValue) })
        self.init(enabled: enabled, enableOnEventTypes: types)
    }

    // NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        return RelevantSamplingConfig(
            enabled: self.enabled,
            enableOnEventTypes: self.enableOnEventTypes
        )
    }
}
