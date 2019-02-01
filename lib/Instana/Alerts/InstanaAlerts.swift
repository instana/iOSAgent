//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaAlerts: NSObject {
    var applicationNotRespondingTreshold: Instana.Types.Seconds? {
        didSet {
            switch (applicationNotRespondingTreshold, applicationNotRespondingMonitor) {
            case (let anrTreshold?, let anrMonitor?):
                anrMonitor.treshold = anrTreshold
            case (let anrTreshold?, .none):
                applicationNotRespondingMonitor = InstanaApplicationNotRespondingMonitor(treshold: anrTreshold)
            default:
                applicationNotRespondingMonitor = nil
            }
        }
    }
    var highCPUUsageTreshold: Float?
    var framerateDipTreshold: UInt?
    
    private var applicationNotRespondingMonitor: InstanaApplicationNotRespondingMonitor?
}
