//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaCrashReporting: NSObject {
    private var crashInstallation: InstanaCrashInstallation?
    
    @objc public func leave(breadcrumb: String) {
        // TODO: implement event
    }
    
    func setup() {
        guard crashInstallation == nil else { return }
        crashInstallation = InstanaCrashInstallation()
    }
}
