//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Object acting as a namespace for configuring alerts.
@objc public class InstanaAlerts: NSObject {
    var applicationNotRespondinThreshold: Instana.Types.Seconds? {
        didSet {
            switch (applicationNotRespondinThreshold, applicationNotRespondingMonitor) {
            case (let anrThreshold?, let anrMonitor?):
                anrMonitor.threshold = anrThreshold
            case (let anrThreshold?, .none):
                applicationNotRespondingMonitor = ApplicationNotRespondingMonitor(threshold: anrThreshold)
            default:
                applicationNotRespondingMonitor = nil
            }
        }
    }
    var lowMemory: Bool = InstanaConfiguration.Defaults.alertLowMemory {
        didSet {
            lowMemoryMonitor = lowMemory ? LowMemoryMonitor() : nil
        }
    }
    var framerateDropThreshold: UInt? {
        didSet {
            switch framerateDropThreshold {
            case let threshold?:
                framerateDropMonitor = FramerateDropMonitor(threshold: threshold)
            default:
                framerateDropMonitor = nil
            }
        }
    }
    
    private var applicationNotRespondingMonitor: ApplicationNotRespondingMonitor?
    private var lowMemoryMonitor: LowMemoryMonitor?
    private var framerateDropMonitor: FramerateDropMonitor?
}
