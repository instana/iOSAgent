//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import CoreTelephony
import UIKit

class InstanaSystemUtils {
    /// Returns device model (for ex. "iPhone10,1")
    static var deviceModel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
    /// Returns iOS version (for ex. "12.1")
    static var systemVersion: String = {
        return UIDevice.current.systemVersion
    }()

    static var systemName: String = {
        return UIDevice.current.systemName
    }()
    
    /// Returns application version (for ex. "1.1")
    static var applicationVersion: String = {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown-version"
    }()
    
    /// Returns application build number (for ex. "123")
    static var applicationBuildNumber: String = {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unkown-build-number"
    }()

    /// Returns bundle identifer (for ex. "com.instana.ios.app")
    static var applicationBundleIdentifier: String = {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "unkown-bundle-id"
    }()

    /// Returns the screen size in Pixel
    static var screenSize: CGSize = {
        return UIScreen.main.nativeBounds.size
    }()
    
    /// Returns carrier name
    static var carrierName: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        return carrier?.carrierName
    }
    
    /// Returns current cellular connection type
    static var cellularConnectionType: String? {
        switch CTTelephonyNetworkInfo().currentRadioAccessTechnology {
        case CTRadioAccessTechnologyGPRS?, CTRadioAccessTechnologyEdge?, CTRadioAccessTechnologyCDMA1x?:
            return "2G"
        case CTRadioAccessTechnologyWCDMA?, CTRadioAccessTechnologyHSDPA?, CTRadioAccessTechnologyHSUPA?, CTRadioAccessTechnologyCDMAEVDORev0?, CTRadioAccessTechnologyCDMAEVDORevA?, CTRadioAccessTechnologyCDMAEVDORevB?, CTRadioAccessTechnologyeHRPD?:
            return "3G"
        case CTRadioAccessTechnologyLTE?:
            return "4G"
        default:
            return nil
        }
    }

    static var isDeviceJailbroken: Bool = {
        var isBroken = false
        do {
            try "Jailbreak Test".write(toFile:"/private/.JailbreakTest.txt", atomically: true, encoding:String.Encoding.utf8)
            isBroken = true
        } catch {}
        if FileManager.default.fileExists(atPath: "/private/var/lib/apt") {
            isBroken = true
        }
        return isBroken
    }()

    static var connectionTypeDescription: String {
        return (InstanaNetworkMonitor.shared.connectionType?.rawValue ?? "") + " - " + (cellularConnectionType ?? "no cellular")
    }
    
    /// Returns a ' > ' sepparated string of view controller class names in the app hierarchy.
    /// This is only a superficial check, and doesn't go deeper than one level.
    static func viewControllersHierarchy() -> String? {
        guard let root = UIApplication.shared.delegate?.window??.rootViewController else { return nil }
        var vcs: [UIViewController] = []
        let rootName = String(describing: type(of: root))
        
        switch root {
        case let nvc as UINavigationController:
            vcs.append(contentsOf: nvc.viewControllers)
        case let tvc as UITabBarController:
            if let selected = tvc.selectedViewController {
                vcs.append(selected)
            }
        case let svc as UISplitViewController:
            vcs.append(contentsOf: svc.viewControllers)
        default:
            break
        }
        
        if let modal = (vcs.last ?? root).presentedViewController {
            vcs.append(modal)
        }
        
        return vcs
            .map { String(describing: type(of: $0)) }
            .reduce(rootName) { "\($0) > \($1)" }
    }
    
    /// Persistent client id stored in user defaults.
    static let clientId: String = {
        let clientIdKey = "INSTANA_CLIENT_ID"
        if let id = UserDefaults.standard.value(forKey: clientIdKey) as? String {
            return id
        }
        else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: clientIdKey)
            return id
        }
    }()
}
