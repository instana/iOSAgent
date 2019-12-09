//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import UIKit

class InstanaSystemUtils {

    static let battery = InstanaBatteryUtils()

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

    static var networkUtility = { NetworkUtility() }()
    
    /// Returns iOS version (for ex. "12.1")
    static var systemVersion: String = { UIDevice.current.systemVersion }()

    static var systemName: String = { UIDevice.current.systemName }()
    
    /// Returns application version (for ex. "1.1")
    static var applicationVersion: String = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown-version" }()
    
    /// Returns application build number (for ex. "123")
    static var applicationBuildNumber: String = { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unkown-build-number" }()

    /// Returns bundle identifer (for ex. "com.instana.ios.app")
    static var applicationBundleIdentifier: String = { Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "unkown-bundle-id" }()

    /// Returns the screen size in Pixel
    static var screenSize: CGSize = { UIScreen.main.nativeBounds.size }()
    
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

    /// Returns a ' > ' sepparated string of view controller class names in the app hierarchy.
    /// This is only a superficial check, and doesn't go deeper than one level.
    static func viewControllersHierarchy() -> String? {
        guard Thread.current.isMainThread else { return nil }
        // This is tricky for multiple window support. which window should we use? TODO: Find a better solution
        // For now we use all rootViewController)
        let hierarchies = UIApplication.shared.windows.compactMap {window -> String? in
            guard let root = window.rootViewController else { return nil }
            var vcs = [UIViewController]()
            let rootName = root.hiercharchyName

            switch root {
            case let nvc as UINavigationController:
                vcs.append(contentsOf: nvc.viewControllers)
            case let tvc as UITabBarController:
                if let selected = tvc.selectedViewController {
                    vcs.append(selected)
                }
            case let svc as UISplitViewController:
                vcs.append(contentsOf: svc.viewControllers)
            default: break
            }

            if let modal = (vcs.last ?? root).presentedViewController {
                vcs.append(modal)
            }
            return vcs
            .map { $0.hiercharchyName }
            .reduce(rootName) { "\($0) > \($1)" }
        }
        let result = hierarchies.joined(separator: "\n")
        return result.isEmpty ? nil : result
    }
}
