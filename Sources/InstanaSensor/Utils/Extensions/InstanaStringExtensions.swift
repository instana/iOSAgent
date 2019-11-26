//  Created by Nikola Lajic on 3/4/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

@objc public extension NSString {
    /// Ensure string is not truncated on a composed character (such as an emoji).
    ///
    /// NSString splits componsed characters, resulting in unusable characters.
    /// - note: Final length might be shorter than `maxLength` if a composed character is at the truncation boundary.
    /// - parameter maxLength: Maximum length of the new string.
    @objc func safelyTruncated(to maxLength: UInt) -> NSString {
        var str = self as String
        guard str.utf8.count > maxLength else { return str as NSString }
        
        str = String(str[..<str.index(str.startIndex, offsetBy: Swift.min(Int(maxLength), str.count))])
        
        while str.utf8.count > maxLength, str.count > 0 {
            str = String(str.dropLast())
        }

        return str as NSString
    }
}
