import Foundation
import UIKit

/// Root object for the Instana agent.
///
///
/// - Important: Before using any of Instana's features, it is necessary to invoke one of its setup methods.
@objc public class Instana: NSObject {
    /// The Container for all Instana monitors (Network, HTTP, Framedrop, ...)
    internal let monitors: Monitors

    /// The current Instana session that holds the configuration, session information, custom properties and more
    internal let session: InstanaSession

    internal static var current: Instana?

    internal let appStateHandler = InstanaApplicationStateHandler.shared

    internal init(configuration: InstanaConfiguration, monitors: Monitors? = nil) {
        let session = InstanaSession(configuration: configuration, propertyHandler: InstanaPropertyHandler())
        self.session = session
        self.monitors = monitors ?? Monitors(session)
        super.init()

        if configuration.isValid {
            self.monitors.reporter.submit(SessionProfileBeacon(state: .start))
        } else {
            session.logger.add("Instana setup is invalid. URL and key must not be empty", level: .error)
        }
    }

    private static var propertyHandler: InstanaPropertyHandler {
        guard let current = Instana.current else {
            InstanaLogger().add("Instana Config error: No active or valid instana session has been setup", level: .error)
            return InstanaPropertyHandler()
        }
        return current.session.propertyHandler
    }

    /// Optional reporting URL used for on-premises Instana backend installations.
    public class var reportingURL: URL? { Instana.current?.session.configuration.reportingURL }

    /// Instana key identifying your application.
    public class var key: String? { Instana.current?.session.configuration.key }

    /// The current session id of this active Instana agent.
    public class var sessionID: String? { Instana.current?.session.id.uuidString }

    /// The current view name you can set via `setView(name: String)`
    public class var viewName: String? { Instana.current?.session.propertyHandler.properties.view }

    /// Configures and sets up the Instana agent with the default configuration.
    /// - HTTP sessions will be captured automatically by default
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    public static func setup(key: String, reportingURL: URL) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL, httpCaptureConfig: .automatic)
        Instana.current = Instana(configuration: config)
    }

    /// Configures and sets up the Instana agent with a custom HTTP capture configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    ///   - httpCaptureConfig: HTTP monitoring configuration to set the capture behavior (automatic, manual or none) http requests & responses
    public static func setup(key: String, reportingURL: URL, httpCaptureConfig: HTTPCaptureConfig = .automatic) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig)
        Instana.current = Instana(configuration: config)
    }

    /// Use this method to manually monitor http requests.
    ///
    /// Start the capture of the http session before using the URLRequest in a URLSession (you can pass a viewName optionally as a second):
    ///
    ///     let marker = Instana.startCapture(urlRequest)
    ///
    /// Finish the marker with the URLResponse and an optional error when the request has been completed
    ///
    ///     marker.finish(response: response, error: error)
    ///
    /// Full example:
    ///
    ///     let marker = Instana.startCapture(request)
    ///     URLSession.shared.dataTask(with: request) { data, response, error in
    ///         marker.finish(response: response, error: error)
    ///     }.resume()
    ///
    ///
    /// You can also capture the HTTP response size manually via the URLSessionDelegate. Like the following:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///             guard let response = task.response else { return }
    ///             marker.set(responseSize: HTTPMarker.Size(response: response, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    ///
    /// - Parameters:
    ///   - request: URLRequest to capture.
    ///   - viewName: (Optional) Name to group the request to a view
    ///
    /// - Returns: HTTP marker to set the response size, finish state or error when the request has been completed.
    public static func startCapture(_ request: URLRequest, viewName: String? = nil) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        let method = request.httpMethod ?? "GET"
        if request.url == nil {
            Instana.current?.session.logger.add("URL must not be nil!", level: .error)
        }
        if delegate == nil {
            Instana.current?.session.logger.add("No valid Instance instance found. Please call setup to create an instance first!", level: .error)
        }
        return HTTPMarker(url: request.url!, method: method, trigger: .manual, delegate: delegate, viewName: viewName)
    }

    ///
    /// Ignore HTTP monitoring for the given URLs
    ///
    /// - Parameters:
    ///     - urls: URLs that will ignored from the Instana monitoring
    public static func setIgnore(urls: [URL]) {
        IgnoreURLHandler.exactURLs = IgnoreURLHandler.exactURLs.union(urls)
    }

    ///
    /// Ignore HTTP monitoring for URLs that match with the given regular expressions
    ///
    /// - Parameters:
    ///     - regex: URLs that match with the given regular expressions will be ignored from monitoring
    public static func setIgnoreURLs(matching regex: [NSRegularExpression]) {
        IgnoreURLHandler.regex = IgnoreURLHandler.regex.union(regex)
    }

    ///
    /// Ignore HTTP monitoring for given URLSession
    ///
    /// - Parameters:
    ///     - session: URLSession to ignore from HTTP monitoring
    public static func ignore(_ session: URLSession) {
        IgnoreURLHandler.urlSessions.insert(session)
        session.configuration.removeInstanaURLProtocol()
    }

    /// Meta data information that will be attached to each transmitted data (beacon).
    /// Consider using this to track UI configuration values, settings, feature flags… any additional context that might be useful for analysis.
    ///
    /// - Parameters:
    ///     - value: An arbitrary String typed value
    ///     - key: The key (String) to store the custom meta value
    public static func setMeta(value: String, key: String) {
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
    /// to see which user initiated a page load.
    ///
    /// Note: By default, Instana will not associate any user-identifiable information to beacons.
    /// Please be aware of the respective data protection laws when choosing to do so.
    /// We generally recommend identification of users via a user ID.
    /// For Instana this is a completely transparent string that is only used to calculate certain metrics.
    /// Name and email can also be used to have access to more filters and a more pleasant presentation of user information.
    ///
    /// - Parameters:
    ///     - id: Unique identifier for the user
    ///     - email: (Optional) User's email address
    ///     - name: (Optional) User's full name
    public static func setUser(id: String, email: String?, name: String?) {
        propertyHandler.properties.user = InstanaProperties.User(id: id, email: email, name: name)
    }

    /// Set the current visible view represented by a custom name.
    ///
    /// This name will be attached to all monitored beacons until you call `setView` again with another name
    /// The name should be unique and not too technical or generic (not just like `WebViewController`)
    /// Consider something like: `WebView: Privacy policy`
    ///
    /// You should call this method in `viewDidAppear`
    ///
    /// - Parameters:
    ///     - name: The name of the current visible view
    public static func setView(name: String) {
        guard propertyHandler.properties.view != name else { return }
        propertyHandler.properties.view = name
        Instana.current?.monitors.reporter.submit(ViewChange(viewName: name))
    }

    /// Report Custom Events
    ///
    /// Custom events enable reporting about non-standard activities,
    /// important interactions and custom timings to Instana.
    /// This can be especially helpful when analyzing uncaught errors (breadcrumbs) and
    /// to track additional performance metrics.
    ///
    /// You can call this method at any time.
    ///
    /// - Parameters:
    ///     - name: Defines what kind of event has happened in your app that should result in the transmission of a custom beacon.
    ///     - timestamp: (Optional) The timestamp when the event has been started.
    ///                  If you don't provide a timestamp, we assume now as timestamp.
    ///                  In case you don't provide a timestamp, but set a duration,
    ///                  we calculate a timestamp by substracting the duration from now. (timestamp = now - duration)
    ///     - duration: (Optional) The duration in milliseconds of how long the event took. Default is zero
    ///     - backendTracingID: (Optional) Use this parameter to relate a beacon to a backend trace.
    ///     - error: (Optional) Error object to provide additional context.
    ///     - meta: (Optional) Key - Value data which can be used to send metadata to Instana just for this singular event
    ///     - viewName: (Optional) Name to group the request to a view (Default is the current view name set via `setView(name: String)`)
    public static func reportEvent(name: String, timestamp: Instana.Types.Milliseconds? = nil, duration: Instana.Types.Milliseconds? = nil, backendTracingID: String? = nil, error: Error? = nil, meta: [String: String]? = nil, viewName: String? = nil) {
        let view = propertyHandler.properties.view
        let beacon = CustomBeacon(timestamp: timestamp,
                                  name: name,
                                  duration: duration,
                                  backendTracingID: backendTracingID,
                                  error: error,
                                  meta: meta,
                                  viewName: viewName ?? view)
        Instana.current?.monitors.reporter.submit(beacon)
    }
}
