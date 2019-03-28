//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Object acting as a namespace for configuring crash reporting.
@objc public class InstanaCrashReporting: NSObject {
    private var crashInstallation: InstanaCrashInstallation?
    
    /// Leave a breadcrumb that will be included in crash reports.
    ///
    /// The total number of breadcrumbs is limited to 100, after that newer breadcrumbs will overwrite older ones.
    /// - Parameter breadcrumb: Will be truncated to 140 characters.
    @objc(leaveBreadcrumb:)
    public func leave(breadcrumb: String) {
        crashInstallation?.addBreadcrumb(breadcrumb)
    }
    
    func setup() {
        guard crashInstallation == nil else { return }
        crashInstallation = InstanaCrashInstallation()
    }
}
