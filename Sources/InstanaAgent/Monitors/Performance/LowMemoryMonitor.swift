//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif

class LowMemoryMonitor {
    let reporter: Reporter

    init(reporter: Reporter) {
        self.reporter = reporter
        #if os(tvOS) || os(watchOS) || os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
        #endif
    }

    @objc func onLowMemoryWarning(notification: Notification) {
        reporter.submit(AlertBeacon(alertType: .lowMemory))
    }
}
