//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import UIKit

var typeAutoCaptureScreenNames: AutoCaptureScreenNames = .none
var autoViewCaptureAllowedClasses: [String] = []

extension UIViewController {
    @objc func instanaViewDidAppear(_ animated: Bool) {
        let className = String(describing: type(of: self))
        if allowCapture(accessibilityLabel: accessibilityLabel,
                        navigationItemTitle: navigationItem.title,
                        className: className) {
            Instana.current?.setViewInternal(name: nil,
                                             accessibilityLabel: accessibilityLabel,
                                             navigationItemTitle: navigationItem.title,
                                             className: className)
        }
        instanaViewDidAppear(animated)
    }

    func allowCapture(accessibilityLabel: String?, navigationItemTitle: String?, className: String) -> Bool {
        if typeAutoCaptureScreenNames == .none { return false }
        if typeAutoCaptureScreenNames == .allUIViewControllers { return true }

        if accessibilityLabel != nil && !accessibilityLabel!.isEmpty ||
            navigationItemTitle != nil && !navigationItemTitle!.isEmpty { return true }
        for allowedClass in autoViewCaptureAllowedClasses where allowedClass == className {
            return true
        }
        return false
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
