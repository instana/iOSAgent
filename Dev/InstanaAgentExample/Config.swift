//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

var InstanaKey: String {
    if let launchArgs = UserDefaults.standard.string(forKey: "key") {
        return launchArgs
    }
    return "INSTANA_REPORTING_KEY"
}

var InstanaURL: URL {
    var value = ""
    if let launchArgs = UserDefaults.standard.string(forKey: "reportingURL") {
        value = launchArgs
    } else {
        value = "INSTANA_REPORTING_URL"
    }
    return URL(string: value)!
}
