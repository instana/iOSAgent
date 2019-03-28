//  Created by Nikola Lajic on 1/24/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

/// Represents errors that can be thrown by the Instana SDK
@objc public class InstanaError: NSError {
    @objc public static let domain = "com.instana.mobile"
    
    @objc public enum Code: Int {
        case invalidRequest
        case invalidResponse
        case notAuthenticated
        case bufferOverwrite
    }
    
    init(code: Code, description: String) {
        super.init(domain: InstanaError.domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
