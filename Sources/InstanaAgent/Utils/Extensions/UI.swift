//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import UIKit

let capturedVCs = NSMapTable<UIViewController, NSNumber>(keyOptions: .weakMemory, valueOptions: .strongMemory)

extension UIViewController {
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
    /// View controller loading time start from beginning of viewDidLoad (or viewWillAppear if already loaded)
    /// to end of viewDidAppear is also measured and sent to Instana backend through duration of beacon.
    @objc
    public static func instanaSetViewAutomatically() {
        // First time a viewController shows, screen rendering time starts from beginning of viewDidLoad
        let viewDidLoadOriginal = class_getInstanceMethod(self, #selector(viewDidLoad))
        let viewDidLoadSwizzled = class_getInstanceMethod(self, #selector(instana_viewDidLoad))
        // Switching among on-screen viewControllers, screen rendering time starts from beginning of viewWillAppear
        let viewWillAppearOriginal = class_getInstanceMethod(self, #selector(viewWillAppear(_:)))
        let viewWillAppearSwizzled = class_getInstanceMethod(self, #selector(instana_viewWillAppear(_:)))
        // Screen rendering time measuring ends
        let viewDidAppearOriginal = class_getInstanceMethod(self, #selector(viewDidAppear(_:)))
        let viewDidAppearSwizzled = class_getInstanceMethod(self, #selector(instana_viewDidAppear(_:)))

        if let originalMethod = viewDidLoadOriginal, let swizzledMethod = viewDidLoadSwizzled {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        if let originalMethod = viewWillAppearOriginal, let swizzledMethod = viewWillAppearSwizzled {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        if let originalMethod = viewDidAppearOriginal, let swizzledMethod = viewDidAppearSwizzled {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc func instana_viewDidLoad() {
        let classType = type(of: self)
        // If `class` belongs to SwiftUI framework
        let bundle = Bundle(for: classType)
        let isSwiftUI = bundle.isSwiftUI
        if allowCapture(accessibilityLabel: accessibilityLabel,
                        navigationItemTitle: navigationItem.title,
                        class: classType,
                        isSwiftUI: isSwiftUI) {
            let startTime = CACurrentMediaTime()
            objc_setAssociatedObject(self, &AssociatedKeys.viewLoadStartTime, startTime, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        instana_viewDidLoad() // Call original
    }

    @objc func instana_viewWillAppear(_ animated: Bool) {
        let classType = type(of: self)
        // If `class` belongs to SwiftUI framework
        let bundle = Bundle(for: classType)
        if allowCapture(accessibilityLabel: accessibilityLabel,
                        navigationItemTitle: navigationItem.title,
                        class: classType,
                        isSwiftUI: bundle.isSwiftUI) {
            // If first time show, viewDidLoad already set the start time, do not override it.
            if objc_getAssociatedObject(self, &AssociatedKeys.viewLoadStartTime) == nil {
                let startTime = CACurrentMediaTime()
                objc_setAssociatedObject(self, &AssociatedKeys.viewLoadStartTime, startTime, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        instana_viewWillAppear(animated) // Call original
    }

    @objc func instana_viewDidAppear(_ animated: Bool) {
        instana_viewDidAppear(animated) // Call original

        if let startTime = objc_getAssociatedObject(self, &AssociatedKeys.viewLoadStartTime) as? CFTimeInterval {
            let duration = (CACurrentMediaTime() - startTime) * 1000.0
            let classType = type(of: self)
            #if DEBUG
                print("DEBUG: \(Bundle(for: classType).bundleIdentifier!) classType=\(classType) viewDidAppear() \(duration) milliseconds")
            #endif
            objc_setAssociatedObject(self, &AssociatedKeys.viewLoadStartTime, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            Instana.current?.setViewInternal(name: nil,
                                             duration: Instana.Types.Milliseconds(duration),
                                             accessibilityLabel: accessibilityLabel,
                                             navigationItemTitle: navigationItem.title,
                                             className: String(describing: classType),
                                             isSwiftUI: Bundle(for: classType).isSwiftUI)
        }
    }

    private struct AssociatedKeys {
        static var viewLoadStartTime: UnsafeRawPointer = UnsafeRawPointer(
            Unmanaged.passUnretained("com.instana.iOSAgent.viewLoadStartTime" as NSString).toOpaque())
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
