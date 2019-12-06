//  Created by Nikola Lajic on 2/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import UIKit

class LowMemoryMonitor {
    
    let reporter: Reporter
    
    init(reporter: Reporter) {
        self.reporter = reporter
        NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    @objc func onLowMemoryWarning(notification: Notification) {
        reporter.submit(AlertBeacon(alertType: .lowMemory))
    }
}
