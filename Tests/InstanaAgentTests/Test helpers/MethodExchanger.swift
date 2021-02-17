//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
import CoreTelephony
@testable import InstanaAgent

/// Aka swi**ling methods

extension UIDevice {
    static var stubBatteryLevel: Float = 0.0
    @objc var stubbedBatteryLevel: Float { UIDevice.stubBatteryLevel }

    static var stubBatteryState: BatteryState = .unknown
    @objc var stubbedBatteryState: BatteryState { UIDevice.stubBatteryState }

    static func swizzleBatteryLevel() {
        let originalMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.batteryLevel))
        let swizzledMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.stubbedBatteryLevel))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    static func swizzleBatteryState() {
        let originalMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.batteryState))
        let swizzledMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.stubbedBatteryState))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension CTTelephonyNetworkInfo {
    static var stubRadioAccessTechnology: String? = "Some"
    @objc var stubbedRadioAccessTechnology: String? { CTTelephonyNetworkInfo.stubRadioAccessTechnology }
    static func swizzleRadioAccessTechnology() {
        let originalMethod = class_getInstanceMethod(CTTelephonyNetworkInfo.self, #selector(getter: CTTelephonyNetworkInfo.currentRadioAccessTechnology))
        let swizzledMethod = class_getInstanceMethod(CTTelephonyNetworkInfo.self, #selector(getter: CTTelephonyNetworkInfo.stubbedRadioAccessTechnology))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
