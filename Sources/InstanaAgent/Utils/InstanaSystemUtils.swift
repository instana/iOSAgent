//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

#if os(macOS)
    import AppKit
#elseif os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif

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

    static var networkUtility = { NetworkUtility.shared }()

    /// Returns iOS version (for ex. "14.4")
    static var systemVersion: String = {
        "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
    }()

    static var systemName: String = {
        let macOS = "macOS"
        if #available(iOS 13.0, *) {
            if ProcessInfo.processInfo.isMacCatalystApp {
                return macOS
            }
        }
        if #available(iOS 14.0, *) {
            if #available(OSX 11.0, *) {
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    return macOS
                }
            }
        }
        #if os(macOS)
            return macOS
        #elseif os(tvOS) || os(watchOS) || os(iOS)
            return UIDevice.current.systemName
        #endif
    }()

    /// Returns application version (for ex. "1.1")
    static var applicationVersion: String = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown-version" }()

    /// Returns application build number (for ex. "123")
    static var applicationBuildNumber: String = { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unkown-build-number" }()

    /// Returns bundle identifer (for ex. "com.instana.ios.app")
    static var applicationBundleIdentifier: String = { Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "unkown-bundle-id" }()

    static var agentVersion: String { VersionConfig.agentVersion }

    /// Returns the screen size in Pixel
    static var screenSize: CGSize = {
        #if os(macOS)
            return NSScreen.main?.frame.size ?? .zero
        #elseif os(tvOS) || os(watchOS) || os(iOS)
            return UIScreen.main.bounds.size
        #endif
    }()

    static var isDeviceJailbroken: Bool = {
        var isBroken = false
        do {
            try "Jailbreak Test".write(toFile: "/private/.JailbreakTest.txt", atomically: true, encoding: String.Encoding.utf8)
            isBroken = true
        } catch {}
        if FileManager.default.fileExists(atPath: "/private/var/lib/apt") {
            isBroken = true
        }
        return isBroken
    }()
}
