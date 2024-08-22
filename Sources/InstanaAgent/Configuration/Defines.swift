//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation

// Default user_session_id refresh time interval as negative number means never refresh
// ie. keep the same user_session_id forever
public let defaultUsiRefreshTimeIntervalInHrs: Double = -1.0

// Do not allow user_session_id tracking
public let usiTrackingNotAllowed: Double = 0.0

let userSessionIDKey = "Instana_UserSessionIDKey"
let usi_startTimeKey = "Instana_usiStartTimeKey"

let ignoreZipReportingKey = "IgnoreZIPReporting"

let maxSlowSendInterval: Instana.Types.Seconds = 3600.0

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

let currentInstanaCrashPayloadVersion = "0.96"
let defaultCrashViewName = "CrashView"

let maxSecondsToKeepCrashLog = (maxDaysToKeepCrashLog * 60 * 60 * 24)

///
/// Internal meta data (im_) key names
///
let internalMetaDataKeyView_accbltyLabel = "view.accLabel" // accessibilityLabel
let internalMetaDataKeyView_navItemTitle = "view.navItemTitle" // navigationItemTitle
let internalMetaDataKeyView_className = "view.clsName" // className

let internalMetaFlutterKeys = ["settings.route.name", "widget.name", "child.widget.name", "child.widget.title", "go.router.path"] // keys given from flutter agent

///
/// Mobile Features
///
let mobileFeatureCrash = "c"
let mobileFeatureAutoScreenNameCapture = "sn"
