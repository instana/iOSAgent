//  Created by Nikola Lajic on 2/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaLowMemoryMonitor {
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onLowMemoryWarning(notification:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func onLowMemoryWarning(notification: Notification) {
        let event = InstanaAlertEvent(alertType: .lowMemory, screen: InstanaSystemUtils.viewControllersHierarchy())
        Instana.events.submit(event: event)
    }
}
