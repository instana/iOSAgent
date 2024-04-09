//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

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

    internal init(session: InstanaSession, monitors: Monitors? = nil) {
        self.session = session
        self.monitors = monitors ?? Monitors(session)
        super.init()

        if !session.configuration.isValid {
            session.logger.add("Instana setup is invalid. URL and key must not be empty", level: .error)
        }
    }

    @objc
    deinit {
        self.monitors.metric?.stopCrashReporting()
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
    public class var viewName: String? { Instana.current?.session.propertyHandler.properties.viewName }

    /// Enable or disable collection (opt-in or opt-out)
    ///
    /// Default: true
    ///
    /// Note: Any instrumentation is ignored when setting `collectionEnabled = false`.
    /// If needed, you can set collectionEnabled to false via Instana's setup and enable the collection later.
    /// (e.g. after giving the consent)
    @objc
    public static var collectionEnabled: Bool {
        set {
            Instana.current?.session.collectionEnabled = newValue
            Instana.current?.monitors.submitStartBeaconIfNeeded()
        }
        get {
            Instana.current?.session.collectionEnabled ?? false
        }
    }

    /// Configures and sets up the Instana agent.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    ///   - options: InstanaSetupOptions which includes collectionEnabled, enableCrashReporting,  slowSendInterval etc.
    ///
    /// - Returns: true on success, false on error
    @objc
    public static func setup(key: String, reportingURL: URL, options: InstanaSetupOptions?) -> Bool {
        return setupInternal(key: key, reportingURL: reportingURL, options: options, hybridOptions: nil)
    }

    /// Internal use, configures and sets up the Instana agent.
    ///
    /// - Parameters:
    ///   - hybridOptions: hybrid  agent configuration options (set if invoked by Instana flutter-agent or react-native-agent)
    ///
    /// - Returns: true on success, false on error
    @objc
    public static func setupInternal(key: String, reportingURL: URL, options: InstanaSetupOptions?,
                                     hybridOptions: HybridAgentOptions?) -> Bool {
        var httpCaptureConfig = HTTPCaptureConfig.automatic
        var collectionEnabled = true
        var enableCrashReporting = false
        var suspendReporting = InstanaConfiguration.SuspendReporting.defaults
        var slowSendInterval = 0.0
        var usiRefreshTimeIntervalInHrs = defaultUsiRefreshTimeIntervalInHrs
        var autoCaptureScreenNames: Bool = false
        var debugAllScreenNames: Bool = false

        if let options = options {
            httpCaptureConfig = options.httpCaptureConfig
            collectionEnabled = options.collectionEnabled
            enableCrashReporting = options.enableCrashReporting

            let suspendReportingOnLowBattery = options.suspendReportingOnLowBattery
            let suspendReportingOnCellular = options.suspendReportingOnCellular
            suspendReporting = []
            if suspendReportingOnLowBattery {
                suspendReporting.insert(InstanaConfiguration.SuspendReporting.lowBattery)
            }
            if suspendReportingOnCellular {
                suspendReporting.insert(InstanaConfiguration.SuspendReporting.cellularConnection)
            }

            let debounce = InstanaConfiguration.Defaults.reporterSendDebounce
            if options.slowSendInterval != 0.0,
                options.slowSendInterval < debounce || options.slowSendInterval > maxSlowSendInterval {
                // Illegal slowSendInterval. Expected value 2 ~ 3600 in seconds
                return false
            }
            slowSendInterval = options.slowSendInterval

            usiRefreshTimeIntervalInHrs = options.usiRefreshTimeIntervalInHrs
            autoCaptureScreenNames = options.autoCaptureScreenNames
            debugAllScreenNames = options.debugAllScreenNames
        }

        var hybridAgentId: String?
        var hybridAgentVersion: String?
        if let hybridOptions = hybridOptions {
            hybridAgentId = hybridOptions.id
            hybridAgentVersion = hybridOptions.version
        }

        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL,
                                                  httpCaptureConfig: httpCaptureConfig,
                                                  enableCrashReporting: enableCrashReporting,
                                                  suspendReporting: suspendReporting,
                                                  slowSendInterval: slowSendInterval,
                                                  usiRefreshTimeIntervalInHrs: usiRefreshTimeIntervalInHrs,
                                                  hybridAgentId: hybridAgentId,
                                                  hybridAgentVersion: hybridAgentVersion)
        let session = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(),
                                     collectionEnabled: collectionEnabled,
                                     autoCaptureScreenNames: autoCaptureScreenNames,
                                     debugAllScreenNames: debugAllScreenNames)
        Instana.current = Instana(session: session)
        return true
    }

    /// Configures and sets up the Instana agent with the default configuration. (deprecated)
    /// - HTTP sessions will be captured automatically by default
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    ///   - enableCrashReporting: Subscribe to metricKit events so as to enable crash reporting.
    ///                      App must have explicitly asked user permission to subscribe before this call.
    @available(*, deprecated, message: "Use method setup(key: String, reportingURL: URL, options: InstanaSetupOptions?)")
    @objc
    public static func setup(key: String, reportingURL: URL, enableCrashReporting: Bool = false) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL,
                                                  httpCaptureConfig: .automatic,
                                                  enableCrashReporting: enableCrashReporting)
        let session = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(), collectionEnabled: true)
        Instana.current = Instana(session: session)
    }

    /// Configures and sets up the Instana agent with a custom HTTP capture configuration. (deprecated)
    ///
    /// - Note: Should be called only once, as soon as posible. Preferably in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key to identify your application.
    ///   - reportingURL: Reporting URL for the Instana backend.
    ///   - httpCaptureConfig: HTTP monitoring configuration to set the capture behavior (automatic, manual, automaticAndManual or none) HTTP requests & responses
    ///   - collectionEnabled: Enable or disable collection (instrumentation) on setup. Can be changed later via the property `collectionEnabled` (Default: true)
    ///   - enableCrashReporting: Subscribe to metricKit events so as to enable crash reporting.
    ///                      App must have explicitly asked user permission to subscribe before this call.
    @available(*, deprecated, message: "Use method setup(key: String, reportingURL: URL, options: InstanaSetupOptions?)")
    @objc
    public static func setup(key: String, reportingURL: URL,
                             httpCaptureConfig: HTTPCaptureConfig = .automatic,
                             collectionEnabled: Bool = true,
                             enableCrashReporting: Bool = false) {
        let config = InstanaConfiguration.default(key: key, reportingURL: reportingURL,
                                                  httpCaptureConfig: httpCaptureConfig,
                                                  enableCrashReporting: enableCrashReporting)
        let session = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(), collectionEnabled: collectionEnabled)
        Instana.current = Instana(session: session)
    }

    /// Manual monitoring of URLRequest.
    ///
    /// Start the capture of the HTTP session before using the URLRequest in a URLSession
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
        return HTTPMarker(url: request.url!,
                          method: method,
                          trigger: .manual,
                          header: request.allHTTPHeaderFields,
                          delegate: delegate,
                          viewName: viewName)
    }

    /// Manual monitoring of URL calls.
    ///
    /// Start the capture of the HTTP session before call the URL (Optionally: Pass a viewName):
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
    ///   - url: URL to capture.
    ///   - method: HTTP Method (e.g. "GET" or "POST")
    ///   - viewName: (Optional) Name of the current view to group the request
    ///
    /// - Returns: HTTP marker to set the response size, finish state or error when the request has been completed.
    @objc
    public static func startCapture(url: URL, method: String, header: [String: String]? = nil, viewName: String? = nil) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        if delegate == nil {
            Instana.current?.session.logger.add("No valid Instance instance found. Please call setup to create an instance first!", level: .error)
        }
        return HTTPMarker(url: url,
                          method: method,
                          trigger: .manual,
                          header: header,
                          delegate: delegate,
                          viewName: viewName)
    }

    ///
    /// Ignore HTTP monitoring for the given URLs
    ///
    /// - Parameters:
    ///     - urls: URLs that will ignored from the Instana monitoring
    @objc
    public static func setIgnore(urls: [URL]) {
        IgnoreURLHandler.ignore(urls: urls)
    }

    ///
    /// Ignore HTTP monitoring for URLs that match with the given regular expressions
    ///
    /// - Parameters:
    ///     - regex: URLs that match with the given regular expressions will be ignored from monitoring
    @objc
    public static func setIgnoreURLs(matching regex: [NSRegularExpression]) {
        IgnoreURLHandler.ignore(regularExpressions: regex)
    }

    ///
    /// Ignore HTTP monitoring for given URLSession
    ///
    /// - Parameters:
    ///     - session: URLSession to ignore from HTTP monitoring
    @objc
    public static func ignore(_ session: URLSession) {
        IgnoreURLHandler.ignore(session: session)
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
        Instana.current?.setViewInternal(name: name)
    }

    public func setViewInternal(name: String?,
                                accessibilityLabel: String? = nil,
                                navigationItemTitle: String? = nil,
                                className: String? = nil,
                                isSwiftUI: Bool = false) {
        guard let propertyHandler = Instana.current?.session.propertyHandler else { return }
        let isIdentical = propertyHandler.properties.view?.isSame(name: name,
                                                                  accessibilityLabel: accessibilityLabel,
                                                                  navigationItemTitle: navigationItemTitle,
                                                                  className: className)
        if isIdentical != nil, isIdentical! { return }
        let view = ViewChange(viewName: name,
                              accessibilityLabel: accessibilityLabel,
                              navigationItemTitle: navigationItemTitle,
                              className: className,
                              isSwiftUI: isSwiftUI)
        propertyHandler.properties.view = view

        guard view.viewName != nil else { return }
        Instana.current?.monitors.reporter.submit(view)
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
    public static func reportEvent(name: String,
                                   timestamp: Instana.Types.Milliseconds = Instana.Types.Milliseconds(NSNotFound),
                                   duration: Instana.Types.Milliseconds = Instana.Types.Milliseconds(NSNotFound),
                                   backendTracingID: String? = nil,
                                   error: Error? = nil,
                                   meta: [String: String]? = nil,
                                   viewName: String? = nil,
                                   customMetric: Double = Double.nan) {
        // As a workaround for primitive values in ObjC
        let timestamp = timestamp == NSNotFound ? nil : timestamp
        let duration = duration == NSNotFound ? nil : duration
        var viewName = viewName ?? CustomBeaconDefaultViewNameID
        viewName = !viewName.isEmpty ? viewName : CustomBeaconDefaultViewNameID

        let customMetric: Double? = customMetric.isNaN ? nil : customMetric

        let beacon = CustomBeacon(timestamp: timestamp,
                                  name: name,
                                  duration: duration,
                                  backendTracingID: backendTracingID,
                                  error: error,
                                  metaData: meta,
                                  viewName: viewName,
                                  customMetric: customMetric)
        Instana.current?.monitors.reporter.submit(beacon)
    }

    ///
    /// Redaction of keys and secrets from captured HTTP requests by providing an
    /// array of NSRegularExpression that match the keywords from the captured HTTP request.
    /// Example: try? NSRegularExpression(pattern: #"pass(word|wort)"#, options: [.caseInsensitive]) to redact the password or passwort parameter
    ///
    /// Default: Instana applies the redaction to all query values corresponding to the parameter: key, secret, password (also myKey or Password)
    ///
    /// - Parameters:
    ///     - regex: Array of NSRegularExpression to find matching keywords for redaction.
    @objc
    public static func redactHTTPQuery(matching regex: [NSRegularExpression]) {
        Instana.current?.monitors.http?.filter.setRedaction(regex: regex)
    }

    ///
    /// HTTP request and response headers can be captured by the iOS agent. You can use regular expressions to define the keys of the HTTP header fields that the iOS agent should capture.
    /// Example: try? NSRegularExpression(pattern: #"X-Key"#, options: [.caseInsensitive]) to capture the X-Key or X-KEY
    ///
    /// Default: No HTTP header fields are captured. Keywords must be provided explicitly
    ///
    /// - Parameters:
    ///     - regex: An array of NSRegularExpression objects to match the key of HTTP request/response headers that you want to capture.
    @objc
    public static func setCaptureHeaders(matching regex: [NSRegularExpression]) {
        Instana.current?.monitors.http?.filter.headerFieldsRegEx = AtomicArray(regex)
    }

    ///
    /// Can catch app crash payloads or not
    ///
    @objc
    public static func canSubscribeCrashReporting() -> Bool {
        if #available(iOS 14.0, *), #available(macOS 12.0, *) {
            return true
        }
        return false
    }

    ///
    /// Setup app crash payloads catching and reporting to server
    /// Warning: If you call this function from a method that deallocates Instana object, your app might crash.
    ///
    @objc
    public static func subscribeCrashReporting() {
        Instana.current?.monitors.subscribeCrashReporting()
    }

    ///
    /// Stop app crash payloads catching
    ///
    @objc
    public static func stopCrashReporting() {
        Instana.current?.monitors.stopCrashReporting()
    }

    ///
    /// Cancel crash (aka diagnostic) reporting
    ///
    /// Diagnostic payloads sent by MetricKit are saved immediately into diagnostic files by Instana agent.
    /// Instana agent finds approriate time to symbolicate the files and send them as beacons to server.
    /// This call cancels symbolicating and beacon reporting process. Diagnostic files are not affected.
    /// Next time when app starts, those cancelled files will be symbolicated again and reported to server.
    ///
    /// - Returns: true if symbolication and beaconizing operation is executing at time of call otherwise false.
    ///
    @objc
    public static func cancelCrashReporting() -> Bool {
        if Instana.current == nil { return false }
        return Instana.current!.monitors.cancelCrashReporting()
    }
}
