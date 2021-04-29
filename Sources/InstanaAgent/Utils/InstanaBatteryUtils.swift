//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif

class InstanaBatteryUtils {
    private(set) var safeForNetworking = true

    init() {
        #if os(tvOS) || os(watchOS) || os(iOS)
            UIDevice.current.isBatteryMonitoringEnabled = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onBatteryLevelDidChange),
                                                   name: UIDevice.batteryLevelDidChangeNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onBatteryStateDidChange),
                                                   name: UIDevice.batteryStateDidChangeNotification,
                                                   object: nil)
            updateSafeForNetworking(0)
        #endif
    }

    @objc func onBatteryLevelDidChange() {
        updateSafeForNetworking(0)
    }

    @objc func onBatteryStateDidChange() {
        updateSafeForNetworking(0)
    }

    func updateSafeForNetworking(_ retry: Int) {
        #if os(tvOS) || os(watchOS) || os(iOS)
            switch UIDevice.current.batteryState {
            case .charging:
                safeForNetworking = UIDevice.current.batteryLevel > 0.02
            case .unplugged:
                safeForNetworking = UIDevice.current.batteryLevel > 0.2
            case .full:
                safeForNetworking = true
            case .unknown:
                // avoiding a possible infinite loop in case the battery state couldn't be determined
                if retry < 1 {
                    UIDevice.current.isBatteryMonitoringEnabled = true
                    updateSafeForNetworking(retry + 1)
                }
            @unknown default:
                break
            }
            if ProcessInfo.isRunningDebugSessionSimulator {
                safeForNetworking = true
            }
        #endif
    }
}
