//  Created by Nikola Lajic on 2/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import UIKit

class LowMemoryMonitor {
    
    let submitter: EventReporter.Submitter
    
    init(submitter: @escaping EventReporter.Submitter = Instana.eventReporter.submit(_:)) {
        self.submitter = submitter
        NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func onLowMemoryWarning(notification: Notification) {
        submitter(AlertEvent(alertType: .lowMemory, screen: InstanaSystemUtils.viewControllersHierarchy()))
    }
}
