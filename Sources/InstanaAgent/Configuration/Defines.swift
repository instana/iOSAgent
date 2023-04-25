//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

let ignoreZipReportingKey = "IgnoreZIPReporting"

let maxDaysToKeepCrashLog = 90

let sessionIDKey = "Instana_SessionIdKey"
let sessionStartTimeKey = "Instana_SessionStartTimeKey"
let viewNameKey = "Instana_ViewNameKey"
let carrierKey = "Instana_CarrierKey"
let connectionTypeKey = "Instana_ConnectionTypeKey"
let userIDKey = "Instana_UserIDKey"
let userEmailKey = "Instana_UserEmailKey"
let userNameKey = "Instana_UserNameKey"

///
/// Crash beacon meta data key names
///
let crashMetaKeyIsSymbolicated = "sym"
let crashMetaKeyInstanaPayloadVersion = "ver"
let crashMetaKeyCrashType = "mt"
let crashMetaKeyGroupID = "mg"
let crashMetaKeySessionID = "id"
let crashMetaKeyViewName = "v"
let crashMetaKeyCarrier = "cn"
let crashMetaKeyConnectionType = "ct"
let crashMetaKeyUserID = "ui"
let crashMetaKeyUserName = "un"
let crashMetaKeyUserEmail = "ue"

let currentInstanaCrashPayloadVersion = "0.91"
let defaultCrashViewName = "CrashView"

let maxSecondsToKeepCrashLog = (maxDaysToKeepCrashLog * 60 * 60 * 24)
