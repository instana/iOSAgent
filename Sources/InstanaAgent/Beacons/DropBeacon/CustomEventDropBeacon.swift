//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation

///
/// CustomEvent dropped beacon class
///
public class CustomEventDropBeacon: DropBeacon {
    var eventName: String
    var view: String?
    var errorCount: Int?
    var errorMessage: String?
    var customMetric: String?

    init(timestamp: Instana.Types.Milliseconds, eventName: String, view: String?,
         errorCount: Int?, errorMessage: String?, customMetric: String?) {
        self.eventName = eventName
        self.view = view
        self.errorCount = errorCount
        self.errorMessage = errorMessage
        self.customMetric = customMetric
        super.init(timestamp: timestamp)
    }

    override func getKey() -> String {
        let view1 = view ?? ""
        let errorMessage1 = errorMessage ?? ""
        let errorCount1 = errorCount ?? 0
        return "\(eventName)|\(errorMessage1)|\(errorCount1)|\(view1)"
    }

    override func toString() -> String? {
        let view1 = view ?? ""
        let errorMessage1 = errorMessage ?? ""
        let errorCount1 = errorCount ?? 0
        let customMetric1 = customMetric ?? ""
        let zInfoExtra = ["cen": eventName, "em": validateLength(errorMessage1, maxLen: 200),
                          "cm": validateLength(customMetric1, maxLen: 100),
                          "v": view1, "ec": errorCount1] as [String: Any]
        return convertToString(type: "custom", subDict: zInfoExtra)
    }
}
