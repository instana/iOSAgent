//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
    import MetricKit
#endif

class DiagnosticBeacon: Beacon {
    let crashSession: PreviousSession
    // group id for all related crashes
    let crashGroupID: UUID
    let crashType: CrashType?
    let crashTime: Instana.Types.Milliseconds
    let duration: Instana.Types.Milliseconds
    let crashPayload: String?
    let formatted: String?
    let errorType: String?
    let errorMessage: String?
    let isSymbolicated: Bool

    init(crashSession: PreviousSession,
         crashGroupID: UUID,
         crashType: CrashType?,
         crashTime: Instana.Types.Milliseconds,
         duration: Instana.Types.Milliseconds,
         crashPayload: String?,
         formatted: String?,
         errorType: String?,
         errorMessage: String?,
         isSymbolicated: Bool) {
        self.crashSession = crashSession
        self.crashGroupID = crashGroupID
        self.crashType = crashType
        self.crashTime = crashTime
        self.duration = duration
        self.crashPayload = crashPayload
        self.formatted = formatted
        self.errorType = errorType
        self.errorMessage = errorMessage
        self.isSymbolicated = isSymbolicated
        super.init(viewName: crashSession.viewName)
    }

    static func createDiagnosticBeacon(payload: DiagnosticPayload, formatted: String?) -> DiagnosticBeacon {
        return DiagnosticBeacon(crashSession: payload.crashSession,
                                crashGroupID: payload.crashGroupID,
                                crashType: payload.crashType,
                                crashTime: payload.crashTime,
                                duration: payload.duration,
                                crashPayload: payload.rawMXPayload,
                                formatted: formatted,
                                errorType: payload.errorType,
                                errorMessage: payload.errorMessage,
                                isSymbolicated: payload.isSymbolicated ?? false)
    }
}
