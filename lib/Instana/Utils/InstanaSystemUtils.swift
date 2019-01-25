//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaSystemUtils {
    /// Returns device model (for ex. "iPhone10,1")
    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    /// Returns iOS version (for ex. "12.1")
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// Returns application version (for ex. "1.1")
    static var applicationVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown-version"
    }
    
    /// Returns application build number (for ex. "123")
    static var applicationBuildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unkown-build-number"
    }
}
