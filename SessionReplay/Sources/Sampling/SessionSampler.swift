//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

internal class SessionSampler {

    /// Handles session sampling decisions using Bernoulli sampling principle.
    /// Deterministic hash-based approach:
    /// SEND = (hash(session_id) mod 100) < samplingPercentage
    static func shouldRecordSession(sessionId: String, samplingPercentage: Int) -> Bool {
        // If sampling is 100%, always record
        if samplingPercentage == 100 {
            return true
        }

        // If sampling is 0%, never record
        if samplingPercentage == 0 {
            return false
        }

        // Get or generate session ID
        let effectiveSessionId = getEffectiveSessionId(sessionId: sessionId)

        // Apply Bernoulli sampling using deterministic hash-based approach
        let hash = effectiveSessionId.hashValue
        let bucket = abs(hash % 100)
        return bucket < samplingPercentage
    }

    /// Gets the effective session ID for sampling decision.
    /// If sessionId is nil or empty, generates a UUID.
    static func getEffectiveSessionId(sessionId: String?) -> String {
        if let sessionId, !sessionId.isEmpty {
            return sessionId
        } else {
            return UUID().uuidString
        }
    }
}
