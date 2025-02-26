//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
#if os(tvOS) || os(watchOS) || os(iOS)
    import UIKit
#endif
import os

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
        let unit = UInt64(1024 * 1024)
        var freeMemory: UInt64?
        if #available(iOS 13.0, *) {
            freeMemory = UInt64(os_proc_available_memory()) / unit
        }
        let maxMemory: UInt64 = ProcessInfo.processInfo.physicalMemory / unit

        // in mega bytes
        reporter.submit(PerfLowMemoryBeacon(availableMemory: freeMemory, maximumMemory: maxMemory))
    }
}
