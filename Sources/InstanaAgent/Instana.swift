//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable line_length

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

    internal init(session: InstanaSession? = nil, configuration: InstanaConfiguration, monitors: Monitors? = nil) {
        let session = session ?? InstanaSession(configuration: configuration, propertyHandler: InstanaPropertyHandler())
        self.session = session
        self.monitors = monitors ?? Monitors(session)
        super.init()

        if configuration.isValid {
            self.monitors.reporter.submit(SessionProfileBeacon(state: .start))
        } else {
            session.logger.add("Instana setup is invalid. URL and key must not be empty", level: .error)
        }
    }

    /// Optional reporting URL used for on-premises Instana backend installations.
    @objc
    public class var reportingURL: URL? { Instana.current?.session.configuration.reportingURL }

    /// Instana key identifying your application.
    @objc
    public class var key: String? { Instana.current?.session.configuration.key }

    /// The current session id of this active Instana agent.
    @objc
    public class var sessionID: String? { Instana.current?.session.id.uuidString }

    /// The current view name you can set via `setView(name: String)`
    @objc
    public class var viewName: String? { Instana.current?.session.propertyHandler.properties.view }

    /// Configures and sets up the Instana agent with the default configuration.
    /// - HTTP sessions will be captured automatically by default
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    @objc
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
    @objc
    public static func setup(key: String, reportingURL: URL, httpCaptureConfig: HTTPCaptureConfig = .automatic) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig)
        Instana.current = Instana(configuration: config)
    }

    /// Manual monitoring of URLRequest.
    ///
    /// Start the capture of the http session before using the URLRequest in a URLSession
    ///
    ///     let marker = Instana.startCapture(urlRequest)
    ///
    /// Optionally: You can pass the viewName
    ///
    ///     let marker = Instana.startCapture(urlRequest, viewName: "Home")
    ///
    /// In order to capture the HTTP response size use the URLSessionDelegate like the following example:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///             guard let response = task.response else { return }
    ///             marker.set(responseSize: HTTPMarker.Size(response: response, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    /// Call finish after the download has been completed and size has been set (Optionally: Pass an error)
    ///
    ///     marker.finish(response: urlResponse, error: error)
    ///
    /// Full example:
    ///
    ///     let marker = Instana.startCapture(request, viewName: "Home")
    ///     URLSession.shared.dataTask(with: request) { data, urlResponse, error in
    ///         marker.finish(response: urlResponse, error: error)
    ///     }.resume()
    ///
    ///
    /// - Parameters:
    ///   - request: URLRequest to capture.
    ///   - viewName: (Optional) Name of the current view to group the request
    ///
    /// - Returns: HTTP marker to set the response size, finish state or error when the request has been completed.
    @objc
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

    /// Manual monitoring of URL calls.
    ///
    /// Start the capture of the http session before call the URL (Optionally: Pass a viewName):
    ///
    ///     let marker = Instana.startCapture(url: URL(string: "https://www.example.com")!, method: "GET", viewName: "Home")
    ///
    /// In order to capture the HTTP response size use the URLSessionDelegate like the following example:
    ///
    ///     func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///          guard let response = task.response else { return }
    ///          marker.set(responseSize: HTTPMarker.Size(response: response, transactionMetrics: metrics.transactionMetrics))
    ///     }
    ///
    /// Call finish after the request has been completed and size has been set (Optionally: Pass an error)
    ///
    ///     marker.finish(response: urlResponse, error: error)
    ///
    ///  If you don't have access to the URLResponse, you can use the HTTPCaptureResult
    ///
    ///     let size = HTTPMarker.Size(header: 123, body: 1024, bodyAfterDecoding: 2048)
    ///     let result = HTTPCaptureResult(statusCode: 200, backendTracingID: "Instana-backend-tracing-id", responseSize: size, error: error)
    ///     marker.finish(result: result)
    ///
    ///
    /// Full example:
    ///
    ///     let url = URL(string: "https://www.example.com")!
    ///     let marker = Instana.startCapture(url: url, method: "GET", viewName: "Home")
    ///     YourNetworkCall(url: url, method: "GET") { (statusCode, error) in
    ///            let size = HTTPMarker.Size(header: 123, body: 1024, bodyAfterDecoding: 2048)
    ///            let result = HTTPCaptureResult(statusCode: statusCode, backendTracingID: "Instana-backend-tracing-id", responseSize: size, error: error)
    ///            marker.finish(result: result)
    ///     }.resume()
    ///
    /// - Parameters:
    ///   - request: URLRequest to capture.
    ///   - method: HTTP Method (e.g. "GET" or "POST")
    ///   - viewName: (Optional) Name of the current view to group the request
    ///
    /// - Returns: HTTP marker to set the response size, finish state or error when the request has been completed.
    @objc
    public static func startCapture(url: URL, method: String, viewName: String? = nil) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        if delegate == nil {
            Instana.current?.session.logger.add("No valid Instance instance found. Please call setup to create an instance first!", level: .error)
        }
        return HTTPMarker(url: url, method: method, trigger: .manual, delegate: delegate, viewName: viewName)
    }

    ///
    /// Ignore HTTP monitoring for the given URLs
    ///
    /// - Parameters:
    ///     - urls: URLs that will ignored from the Instana monitoring
    @objc
    public static func setIgnore(urls: [URL]) {
        IgnoreURLHandler.exactURLs = IgnoreURLHandler.exactURLs.union(urls)
    }

    ///
    /// Ignore HTTP monitoring for URLs that match with the given regular expressions
    ///
    /// - Parameters:
    ///     - regex: URLs that match with the given regular expressions will be ignored from monitoring
    @objc
    public static func setIgnoreURLs(matching regex: [NSRegularExpression]) {
        IgnoreURLHandler.regex = IgnoreURLHandler.regex.union(regex)
    }

    ///
    /// Ignore HTTP monitoring for given URLSession
    ///
    /// - Parameters:
    ///     - session: URLSession to ignore from HTTP monitoring
    @objc
    public static func ignore(_ session: URLSession) {
        IgnoreURLHandler.urlSessions.insert(session)
        session.configuration.removeInstanaURLProtocol()
    }

    /// Meta data information that will be attached to each transmitted data (beacon).
    /// Consider using this to track UI configuration values, settings, feature flags… any additional context that might be useful for analysis.
    ///
    /// Note: We currently support up to 64 meta key/value pairs.
    ///
    /// - Parameters:
    ///     - value: An arbitrary String typed value
    ///     - key: The key (String) to store the custom meta value
    @objc
    public static func setMeta(value: String, key: String) {
        guard let propertyHandler = Instana.current?.session.propertyHandler else { return }
        propertyHandler.properties.appendMetaData(key, value)
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
    @objc
    public static func setUser(id: String, email: String?, name: String?) {
        Instana.current?.session.propertyHandler.properties.user = InstanaProperties.User(id: id, email: email, name: name)
    }

    ///
    /// Set an unique identifier for the User
    /// - Parameters:
    ///     - id: Unique identifier for the user
    @objc
    public static func setUser(id: String) {
        let user = Instana.current?.session.propertyHandler.properties.user
        setUser(id: id, email: user?.email, name: user?.name)
    }

    ///
    /// Set user's email address
    /// - Parameters:
    ///     - email: User's email address
    @objc
    public static func setUser(email: String) {
        let user = Instana.current?.session.propertyHandler.properties.user
        setUser(id: user?.id ?? "", email: email, name: user?.name)
    }

    ///
    /// Set user's name
    /// - Parameters:
    ///     - name: User's full name
    @objc
    public static func setUser(name: String) {
        let user = Instana.current?.session.propertyHandler.properties.user
        setUser(id: user?.id ?? "", email: user?.email, name: name)
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
    @objc
    public static func setView(name: String) {
        guard let propertyHandler = Instana.current?.session.propertyHandler else { return }
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
    /// We need to use a String type for timestamp & duration, because ObjC does not allow optional Int64 parameter in method signatures.
    /// The String typed timestamp & duration will be converted to Int64 internally.
    ///
    /// You can call this method at any time.
    ///
    /// - Parameters:
    ///     - name: Defines what kind of event has happened in your app that should result in the transmission of a custom beacon.
    ///     - timestamp: The timestamp in milliseconds when the event has been started.
    ///                  If you don't provide a timestamp, we assume now as timestamp.
    ///                  In case you don't provide a timestamp, but set a duration,
    ///                  we calculate a timestamp by substracting the duration from now. (timestamp = now - duration)
    ///     - duration: The duration in milliseconds of how long the event lasted. Default is nil (= unused)
    ///     - backendTracingID: (Optional) Identifier to create a backend trace for this event.
    ///     - error: (Optional) Error object to provide additional context.
    ///     - meta: (Optional) Key - Value data which can be used to send metadata to Instana just for this singular event
    ///     - viewName: (Optional) You can pass a String to group the request to a view.
    ///                            Alternatively you can leave out the parameter or send
    ///                            nil to use the current view name implicitly you did set in `setView(name: String)`
    @objc
    public static func reportEvent(name: String, timestamp: Instana.Types.Milliseconds = Instana.Types.Milliseconds(NSNotFound), duration: Instana.Types.Milliseconds = Instana.Types.Milliseconds(NSNotFound), backendTracingID: String? = nil, error: Error? = nil, meta: [String: String]? = nil, viewName: String? = nil) {
        // As a workaround for primitive values in ObjC
        let timestamp = timestamp == NSNotFound ? nil : timestamp
        let duration = duration == NSNotFound ? nil : duration
        var viewName = viewName ?? CustomBeaconDefaultViewNameID
        viewName = !viewName.isEmpty ? viewName : CustomBeaconDefaultViewNameID
        let beacon = CustomBeacon(timestamp: timestamp,
                                  name: name,
                                  duration: duration,
                                  backendTracingID: backendTracingID,
                                  error: error,
                                  metaData: meta,
                                  viewName: viewName)
        Instana.current?.monitors.reporter.submit(beacon)
    }
}
