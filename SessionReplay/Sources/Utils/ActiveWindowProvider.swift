//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import UIKit

// helper for unit test
protocol ActiveWindowProvider {
    var activeKeyWindow: UIWindow? { get }
}

@available(iOS 13.0, *)
struct AppWindowProvider: ActiveWindowProvider {
    var activeKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
    }
}
