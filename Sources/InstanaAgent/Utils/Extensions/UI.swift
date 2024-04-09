//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import UIKit

extension UIViewController {
    @objc func instanaViewDidAppear(_ animated: Bool) {
        let classType = type(of: self)
        // If `class` belongs to SwiftUI framework
        let isSwiftUI = Bundle(for: classType).isSwiftUI
        if allowCapture(accessibilityLabel: accessibilityLabel,
                        navigationItemTitle: navigationItem.title,
                        class: classType,
                        isSwiftUI: isSwiftUI) {
            Instana.current?.setViewInternal(name: nil,
                                             accessibilityLabel: accessibilityLabel,
                                             navigationItemTitle: navigationItem.title,
                                             className: String(describing: classType),
                                             isSwiftUI: isSwiftUI)
        }
        instanaViewDidAppear(animated)
    }

    func allowCapture(accessibilityLabel: String?, navigationItemTitle: String?,
                      class: AnyClass, isSwiftUI: Bool) -> Bool {
        let localAcsn = Instana.current?.session.autoCaptureScreenNames
        if localAcsn == nil || !localAcsn! {
            // Auto view capture feature is disabled
            return false
        }

        if Instana.current!.session.debugAllScreenNames {
            // Debug mode capture all
            return true
        }

        if accessibilityLabel != nil && !accessibilityLabel!.isEmpty ||
            navigationItemTitle != nil && !navigationItemTitle!.isEmpty {
            return true
        }

        guard !Bundle(for: `class`).isSystemBundle else {
            // UIViewController not subclassed is deemed as system class and is not auto captured
            return false
        }

        // When no visible view name available,
        // for SwiftUI, not capture;
        // for UIKit, allow capture.
        return !isSwiftUI
    }

    /// setView name for Instana with current UIViewController's class name when viewDidAppear method is called.
    /// This applies to all View Controllers that inherit from UIViewController.
    ///
    /// This method only needs to be called once during app life cycle.
    ///
    /// Remove Instana.setView calls from all View Controllers that inherit from UIViewController
    /// otherwise the old approach interferes with this new approach.
    ///
    /// If SwiftUI APIs are used, set navigationTitle for the View.
    /// This navigationTitle becomes view name of Instana's view.
    ///
    @objc
    public static func instanaSetViewAutomatically() {
        let originalSelector = #selector(UIViewController.viewDidAppear)
        let swizzledSelector = #selector(UIViewController.instanaViewDidAppear)
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

internal extension Bundle {
    var isSystemBundle: Bool {
        return bundleURL.lastPathComponent == "UIKitCore.framework" // iOS 12+
            || bundleURL.lastPathComponent == "UIKit.framework" // iOS 11
    }

    var isSwiftUI: Bool {
        return bundleURL.lastPathComponent == "SwiftUI.framework"
    }
}
