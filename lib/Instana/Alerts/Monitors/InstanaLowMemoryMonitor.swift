//  Created by Nikola Lajic on 2/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaLowMemoryMonitor {
    
    let submitEvent: InstanaEvents.Submitter
    
    init(submitEvent: @escaping InstanaEvents.Submitter = Instana.events.submit(event:)) {
        self.submitEvent = submitEvent
        NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func onLowMemoryWarning(notification: Notification) {
        let event = InstanaAlertEvent(alertType: .lowMemory, screen: InstanaSystemUtils.viewControllersHierarchy())
        submitEvent(event)
    }
}
