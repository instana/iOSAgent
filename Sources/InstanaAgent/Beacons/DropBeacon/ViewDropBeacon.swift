//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation

///
/// View dropped beacon class
///
public class ViewDropBeacon: DropBeacon {
    var viewName: String?
    var imMap: [String: String]?

    init(timestamp: Instana.Types.Milliseconds, viewName: String?, imMap: [String: String]?) {
        self.viewName = viewName
        self.imMap = imMap
        super.init(timestamp: timestamp)
    }

    override func getKey() -> String {
        let viewName1 = viewName ?? ""
        let imStr = dictionaryToJsonString(imMap) ?? ""
        return "\(viewName1)|\(imStr)"
    }

    override func toString() -> String? {
        let viewName1 = viewName ?? ""
        let zInfoExtra = ["view": viewName1, "im_": imMap ?? [:]] as [String: Any]
        return convertToString(type: "VIEW", subDict: zInfoExtra)
    }
}
