import UIKit

// TODO: Test this
extension UIViewController {
    var hiercharchyName: String {
        var name = String(describing: type(of: self))
        if let title = (title ?? restorationIdentifier ?? nibName) {
            name += " - (" + title + ")"
        }
        return name
    }
}

extension UIWindow {
    static var viewControllerHierarchies: String? {
        let hierarchies = UIApplication.shared.windows.compactMap { window -> String? in
            guard let root = window.rootViewController else { return nil }
            var vcs = [UIViewController]()
            let rootName = root.hiercharchyName

            switch root {
            case let nvc as UINavigationController:
                vcs.append(contentsOf: nvc.viewControllers)
            case let tvc as UITabBarController:
                if let selected = tvc.selectedViewController {
                    vcs.append(selected)
                }
            case let svc as UISplitViewController:
                vcs.append(contentsOf: svc.viewControllers)
            default: break
            }

            if let modal = (vcs.last ?? root).presentedViewController {
                vcs.append(modal)
            }
            return vcs
                .map { $0.hiercharchyName }
                .reduce(rootName) { "\($0) > \($1)" }
        }
        let result = hierarchies.joined(separator: "\n")
        return result.isEmpty ? nil : result
    }
}
