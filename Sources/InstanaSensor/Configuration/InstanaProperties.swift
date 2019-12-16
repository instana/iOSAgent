import Foundation

struct InstanaProperties {
    struct User: Identifiable {
        /// Unique identifier for the user
        var id: String
        /// User's email address
        var email: String?
        /// User's full name
        var name: String?
    }

    var user: User?
    var metaData: [String: String]?
    var view: String?
}

@objc public class InstanaPropertyHandler: NSObject {
    private var _unsafe_properties = InstanaProperties()
    private let lock = NSLock()
    var properties: InstanaProperties {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _unsafe_properties
        }
        set {
            lock.lock()
            _unsafe_properties = newValue
            lock.unlock()
        }
    }

    /// User-specific information
    ///
    /// This information can optionally be sent with data transmitted to Instana.
    /// It can then be used to unlock additional capabilities such as:
    /// calculate the number of users affected by errors,
    /// to filter data for specific users and
    /// to see which user initiated a page load / AJAX call.
    ///
    /// Note: By default, Instana will not associate any user-identifiable information to beacons.
    /// Please be aware of the respective data protection laws when choosing to do so.
    /// We generally recommend identification of users via a user ID.
    /// For Instana this is a completely transparent string that is only used to calculate certain metrics.
    /// UserName and userEmail can also be used to have access to more filters and a more pleasant presentation of user information.
    ///
    /// - Parameters:
    ///     - id: Unique identifier for the user
    ///     - email: User's email address
    ///     - name: User's full name
    @objc public func setUser(id: String, email: String?, name: String?) {
        properties.user = InstanaProperties.User(id: id, email: email, name: name)
    }

    /// Meta data information that will be attached to each transmitted data (beacon).
    /// Consider using this to track UI configuration values, settings, feature flags… any additional context that might be useful for analysis.
    ///
    /// - Parameters:
    ///     - value: An arbitrary String typed value
    ///     - key: The key (String) to store the custom meta value
    @objc public func setMeta(value: String, key: String) {
        var metaData = properties.metaData ?? [:]
        metaData[key] = value
        properties.metaData = metaData
    }

    /// Set the current visible view / window represented by a custom name.
    ///
    /// This name will be attached to all monitored events until you call `unsetVisibleView`
    /// The name should be unique and not too technical or generic (not just like `WebViewController`)
    /// Consider something like: `WebView: Privacy policy`
    /// 
    /// Note: This must be handled manually since an iOS app can have multiple windows or `UIViewController` showing at the same time
    ///
    /// Important: Make sure to set the current view name in `viewDidAppear` and unset the name in `viewWillDisappear` by calling `unsetVisibleView`
    ///
    /// - Parameters:
    ///     - name: The name of the current visible view
    @objc public func setVisibleView(name: String) {
        properties.view = name
    }

    /// Unset the current visible view name.
    ///
    /// Reset the current view name in `viewWillDisappear`.
    ///
    /// - Parameters:
    ///     - name: The name of the current visible view
    @objc public func unsetVisibleView() {
        properties.view = nil
    }
}
