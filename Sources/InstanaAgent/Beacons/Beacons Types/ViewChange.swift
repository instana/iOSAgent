//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class ViewChange: Beacon {
    var accessibilityLabel: String?
    var navigationItemTitle: String?
    var className: String?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         viewName: String? = nil, accessibilityLabel: String? = nil,
         navigationItemTitle: String? = nil, className: String? = nil) {
        var canonicalName: String? = viewName
        var prefix = ""
        if accessibilityLabel != nil, !accessibilityLabel!.isEmpty {
            self.accessibilityLabel = ViewChange.validate(viewName: accessibilityLabel)
            prefix = self.accessibilityLabel! + " "
        }
        if self.accessibilityLabel == nil, navigationItemTitle != nil, !navigationItemTitle!.isEmpty {
            self.navigationItemTitle = ViewChange.validate(viewName: navigationItemTitle)
            prefix = self.navigationItemTitle! + " "
        }
        self.className = className
        if self.className != nil {
            canonicalName = prefix + "@" + self.className!
        }
        super.init(timestamp: timestamp, viewName: canonicalName)
    }

    func isSame(name: String?, accessibilityLabel: String?, navigationItemTitle: String?,
                className: String?) -> Bool {
        if name != viewName || self.accessibilityLabel != accessibilityLabel
            || self.navigationItemTitle != navigationItemTitle || self.className != className {
            return false
        }
        return true
    }

    static func validate(viewName: String?) -> String? {
        guard let value = viewName else { return nil }
        return value.cleanEscapeAndTruncate(at: InstanaProperties.viewMaxLength)
    }
}
