//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

// Place all URLs or patterns here that should be ignored from being monitored in the automatic instrumentation

struct DefaultIgnoredURLs {
    static var excludedURLs: [URL] { [] }
    static var excludedPatterns: [String] { [".*instabug.com.*"] }
}
