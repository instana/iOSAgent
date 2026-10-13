//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

/// Defines the types of relevant events that can trigger automatic session replay data flushing.
///
/// These event types are used in conjunction with `RelevantSamplingConfig` to determine when
/// buffered session replay data should be automatically transmitted to the Instana backend.

@objc public enum RelevantSessionType: Int {
    /// User frustration signals indicating poor user experience.
    ///
    /// When enabled, session replay data will be automatically flushed when frustration
    /// signals are detected, including:
    /// - **Rage Taps**: Rapid repeated taps on interactive elements
    /// - **Frequent Restarts**: User repeatedly restarting the application
    ///
    /// These signals help identify usability issues and areas where users are experiencing
    /// difficulties, even if no technical error occurs.
    case frustration = 1
}
