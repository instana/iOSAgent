//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaAlerts: NSObject {
    var applicationNotRespondinThreshold: Instana.Types.Seconds? {
        didSet {
            switch (applicationNotRespondinThreshold, applicationNotRespondingMonitor) {
            case (let anrThreshold?, let anrMonitor?):
                anrMonitor.threshold = anrThreshold
            case (let anrThreshold?, .none):
                applicationNotRespondingMonitor = InstanaApplicationNotRespondingMonitor(threshold: anrThreshold)
            default:
                applicationNotRespondingMonitor = nil
            }
        }
    }
    var lowMemory: Bool = InstanaConfiguration.Defaults.alertLowMemory {
        didSet {
            lowMemoryMonitor = lowMemory ? InstanaLowMemoryMonitor() : nil
        }
    }
    var framerateDipThreshold: UInt? {
        didSet {
            switch framerateDipThreshold {
            case let threshold?:
                framerateDipMonitor = InstanaFramerateDipMonitor(threshold: threshold)
            default:
                framerateDipMonitor = nil
            }
        }
    }
    
    private var applicationNotRespondingMonitor: InstanaApplicationNotRespondingMonitor?
    private var lowMemoryMonitor: InstanaLowMemoryMonitor?
    private var framerateDipMonitor: InstanaFramerateDipMonitor?
}
