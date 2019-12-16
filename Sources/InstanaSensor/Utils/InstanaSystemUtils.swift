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
        return UIWindow.viewControllerHierarchies
    }
}
