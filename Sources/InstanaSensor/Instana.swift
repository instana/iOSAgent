import Foundation

/// Root object for the InstanaSensor.
///
///
/// - Important: Before using any of Instana's features, it is necessary to invoke one of its setup methods.
@objc public class Instana: NSObject {
    /// The Container for all Instana monitors (Network, HTTP, Framedrop, ...)
    let monitors: Monitors

    /// The current Instana environment that holds the configuration, session information, custom properties and more
    let environment: InstanaEnvironment

    static var current: Instana?

    init(configuration: InstanaConfiguration, monitors: Monitors? = nil) {
        let environment = InstanaEnvironment(configuration: configuration, propertyHandler: InstanaPropertyHandler())
        self.environment = environment
        self.monitors = monitors ?? Monitors(environment)
        super.init()
        assert(!configuration.reportingURL.absoluteString.isEmpty, "Instana Reporting URL must not be empty")
        if configuration.isValid {
            self.monitors.reporter.submit(SessionProfileBeacon(state: .start, sessionID: environment.sessionID))
        }
    }
}

/// Public API methods
@objc public extension Instana {
    /// Optional reporting URL used for on-premises Instana backend installations.
    class var reportingURL: URL? { Instana.current?.environment.configuration.reportingURL }

    /// Instana key identifying your application.
    class var key: String? { Instana.current?.environment.configuration.key }

    /// Configures and sets up the Instana SDK with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key identifying your application.
    ///   - reportingURL: Optional reporting URL used for on-premises Instana backend installations.
    static func setup(key: String, reportingURL: URL? = nil, reportingType: ReportingType = .automaticAndManual) {
        // TODO: leave when current a session exists
        // Currently setup would be possible n times in one app lifecycle
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL, reportingType: reportingType)
        Instana.current = Instana(configuration: config)
    }

    // TODO: Move this into a namedspace wrapper
    /// Use this method to manually monitor remote calls that can't be tracked automatically.
    ///
    ///
    /// Monitor the response of this request like this:
    ///
    ///     let marker = Instana.markHTTPCall(url, method: "GET")
    ///     URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if let error = error {
    ///             marker.finished(error: error)
    ///         } else {
    ///             marker.finished(responseCode: (response as? HTTPURLResponse)?.statusCode ?? 200)
    ///         }
    ///     }
    ///
    /// You can also trace the HTTP reponse size manually once the size has been determined via the URLSessionDelegate. For example:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///            marker?.set(responseSize: Instana.Types.HTTPSize(task: task, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    ///
    /// - Parameters:
    ///   - url: URL of the call.
    ///   - method: Method of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    static func markHTTP(_ url: URL, method: String) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        return HTTPMarker(url: url, method: method, trigger: .manual, delegate: delegate)
    }

    /// Use this method to manually monitor remote calls that can't be tracked automatically.
    ///
    /// Monitor the response of this request like this::
    ///
    ///     let marker = Instana.markHTTP(urlRequest)
    ///     URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if let error = error {
    ///             marker.finished(error: error)
    ///         } else {
    ///             marker.finished(responseCode: (response as? HTTPURLResponse)?.statusCode ?? 200)
    ///         }
    ///     }
    ///
    /// You can also trace the HTTP reponse size manually once the size has been determined via the URLSessionDelegate.
    /// (Must be called before finished) For example:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///            marker?.set(responseSize: Instana.Types.HTTPSize(task: task, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    /// - Parameters:
    ///   - request: URLRequest of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    static func markHTTP(_ request: URLRequest) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        let url = request.url ?? URL(string: "http://instana-invalid")!
        return HTTPMarker(url: url, method: request.httpMethod ?? "invalid", trigger: .manual, delegate: delegate)
    }

    ///
    /// Set the properties
    ///
    internal static var propertyHandler: InstanaPropertyHandler {
        guard let current = Instana.current else { fatalError("Instana Config error: There is no active & valid instana setup") }
        return current.environment.propertyHandler
    }

    /// Meta data information that will be attached to each transmitted data (beacon).
    /// Consider using this to track UI configuration values, settings, feature flags… any additional context that might be useful for analysis.
    ///
    /// - Parameters:
    ///     - value: An arbitrary String typed value
    ///     - key: The key (String) to store the custom meta value
    static func setMeta(value: String, key: String) {
        guard propertyHandler.validate(value: value) else { return }
        var metaData = propertyHandler.properties.metaData ?? [:]
        metaData[key] = value
        if propertyHandler.validate(keys: Array(metaData.keys)) {
            propertyHandler.properties.metaData = metaData
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
    static func setUser(id: String, email: String?, name: String?) {
        propertyHandler.properties.user = InstanaProperties.User(id: id, email: email, name: name)
    }

    /// Set the current visible view / window represented by a custom name.
    ///
    /// This name will be attached to all monitored events until you call `setView` again with another name
    /// The name should be unique and not too technical or generic (not just like `WebViewController`)
    /// Consider something like: `WebView: Privacy policy`
    ///
    /// Note: This must be handled manually since an iOS app can have multiple windows or `UIViewController` showing at the same time
    ///
    /// You should call this method in `viewDidAppear`
    ///
    /// - Parameters:
    ///     - name: The name of the current visible view
    static func setView(name: String) {
        propertyHandler.properties.view = name
    }
}
