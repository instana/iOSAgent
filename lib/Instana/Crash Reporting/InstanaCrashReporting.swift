//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaCrashReporting: NSObject {
    private var crashInstallation: InstanaCrashInstallation?
    
    @objc(leaveBreadcrumb:)
    public func leave(breadcrumb: String) {
        crashInstallation?.addBreadcrumb(breadcrumb)
    }
    
    func setup() {
        guard crashInstallation == nil else { return }
        crashInstallation = InstanaCrashInstallation()
    }
}
