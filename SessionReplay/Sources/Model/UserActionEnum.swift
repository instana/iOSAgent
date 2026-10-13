//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

enum UserActionEnum: String {
    case touch          = "t"
    case tap            = "tp"
    case orientation    = "oc"
    case keyboardOperation = "ke"
    case frustrationSignal = "fs"
    case appState          = "as"
}

// consts - beacon keys sent to backend
let userActionKey_orientationChange = UserActionEnum.orientation.rawValue
let userActionKey_keyboardOperation = "ko"
let userActionKey_frustrationSignal = UserActionEnum.frustrationSignal.rawValue
let userActionKey_appState = UserActionEnum.appState.rawValue

enum OrientationValueEnum: String {
    case unknown    = "u"
    case landscape  = "l"
    case Portrait   = "p"
}

enum KeyboardOperationValueEnum: String {
    case open   = "o"
    case close  = "c"
}

enum AppStateValueEnum: String {
    case background = "bg"
    case foreground = "fg"
}

enum FrustrationSignalValueEnum: String {
    case frequentAppKillRestart = "fkr"
    case rageTap = "rt"
    case deadTap = "dt"
}
