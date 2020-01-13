import Foundation
import UIKit

/// Root object for the InstanaAgent.
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
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            InstanaSystemUtils.isAppActive = true
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            InstanaSystemUtils.isAppActive = false
        }
    }

    internal static var propertyHandler: InstanaPropertyHandler {
        guard let current = Instana.current else { fatalError("Instana Config error: There is no active & valid instana setup") }
        return current.environment.propertyHandler
    }
}

/// Public API methods
@objc public extension Instana {
    /// Optional reporting URL used for on-premises Instana backend installations.
    class var reportingURL: URL? { Instana.current?.environment.configuration.reportingURL }

    /// Instana key identifying your application.
    class var key: String? { Instana.current?.environment.configuration.key }

    /// Configures and sets up the Instana Agent with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Optional reporting URL used for on-premises Instana backend installations.
    ///   - httpCaptureConfig: Optional configuration to set the capture behavior for the outgoing http requests
    static func setup(key: String, reportingURL: URL? = nil, httpCaptureConfig: HTTPCaptureConfig = .automatic) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig)
        Instana.current = Instana(configuration: config)
    }

    /// Use this method to manually monitor http requests.
    ///
    /// Start the capture of the http session before using the URLRequest in a URLSession (you can set a viewName optionally):
    ///
    ///     try? Instana.startCapture(urlRequest)
    ///
    /// Finish the marker with the status code or an error when the request has been completed
    ///
    ///     marker?.finish(responseCode: code)
    /// or with an error
    ///
    ///     marker?.finish(error: error)
    ///
    /// Full example:
    ///
    ///     let marker = try? Instana.startCapture(request)
    ///     URLSession.shared.dataTask(with: request) { data, response, error in
    ///         if let error = error {
    ///             marker?.finish(error: error)
    ///         } else {
    ///             let code = (response as? HTTPURLResponse)?.statusCode ?? 200
    ///             marker?.finish(responseCode: code)
    ///         }
    ///     }.resume()
    ///
    ///
    /// You can also capture the HTTP response size manually once the size has been determined via the URLSessionDelegate. Like the following:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///            marker?.set(responseSize: Instana.Types.HTTPSize(task: task, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    ///
    /// - Parameters:
    ///   - request: URLRequest to capture.
    ///   - viewName: Optional name of the visible view that belongs to this http request
    ///
    ///   - Returns: HTTP marker to set the response size, finish state or error when the request has been completed.
    static func startCapture(_ request: URLRequest, viewName: String? = nil) throws -> HTTPMarker {
        guard let delegate = Instana.current?.monitors.http else {
            throw InstanaError(code: .instanaInstanceNotFound, description: "No valid Instance instance found. Please call setup to create instance first!")
        }
        guard let url = request.url else {
            throw InstanaError(code: .invalidURL, description: "URL is invalid.")
        }
        let method = request.httpMethod ?? "GET"
        return HTTPMarker(url: url, method: method, trigger: .manual, delegate: delegate, viewName: viewName)
    }

    ///
    /// Ignore HTTP monitoring for the given URLs
    ///
    /// - Parameters:
    ///     - urls: URLs that will ignored from the Instana monitoring
    static func ignore(urls: [URL]) {
        IgnoreURLHandler.exactURLs = urls
    }

    ///
    /// Ignore HTTP monitoring for a URL that matches with the given regular expressions
    ///
    /// - Parameters:
    ///     - urls: URLs that match with the given regular expressions will be ignored from monitored
    static func ignoreURL(matching regex: [String]) {
        IgnoreURLHandler.regexPatterns = regex
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

    /// Set the current visible view represented by a custom name.
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
        Instana.current?.monitors.reporter.submit(ViewChange(viewName: name))
    }
}
