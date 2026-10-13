//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
extension UIApplication: ActiveWindowProvider {
     var activeKeyWindow: UIWindow? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
    }

    static var swizzleOn = false
    static func setupSwizzle() {
        // touch
        let original = class_getInstanceMethod(UIApplication.self, #selector(sendEvent(_:)))
        let swizzled = class_getInstanceMethod(UIApplication.self, #selector(swizzled_sendEvent(_:)))
        if let original = original, let swizzled = swizzled {
            method_exchangeImplementations(original, swizzled)
        }
        // sendAction
        let originalSelector = class_getInstanceMethod(UIApplication.self, #selector(sendAction(_:to:from:for:)))
        let swizzledSelector = class_getInstanceMethod(UIApplication.self, #selector(swizzled_sendAction(_:to:from:for:)))
        if let originalSelector = originalSelector, let swizzledSelector = swizzledSelector {
            method_exchangeImplementations(originalSelector, swizzledSelector)
        }
    }
    static func toggleSwizzle(_ enabled: Bool) {
        swizzleOn = enabled
    }

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if UIApplication.swizzleOn {
            InstanaSessionReplay.current?.processSendEvent(event)
        }
        swizzled_sendEvent(event) // Call original
    }

    @objc func swizzled_sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        if UIApplication.swizzleOn {
            InstanaSessionReplay.current?.processSendAction(action, to: target, from: sender, for: event)
        }
        return swizzled_sendAction(action, to: target, from: sender, for: event) // Call original
    }
}
