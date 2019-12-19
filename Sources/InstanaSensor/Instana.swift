//  Created by Nikola Lajic on 12/10/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Root object for the InstanaSensor.
///
///
/// - Important: Before using any of Instana's features, it is necessary to invoke one of its setup methods.
@objc public class Instana: NSObject {

    /// MARK: Framework Internal
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
    @objc class var reportingURL: URL? { Instana.current?.environment.configuration.reportingURL }

    /// Instana key identifying your application.
    @objc class var key: String? { Instana.current?.environment.configuration.key }

    /// Instana global property handler that will attach the custom properties to each monitored event. (beacon)
    /// Those values can be changed any time by the InstanaAgent consumer (i.e. iOS app).
    /// This class is thread-safe
    @objc class var propertyHandler: InstanaPropertyHandler {
        guard let current = Instana.current else { fatalError("Instana Config error: There is no active & valid instana setup") }
        return current.environment.propertyHandler
    }

    /// Configures and sets up the Instana SDK with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key identifying your application.
    ///   - reportingURL: Optional reporting URL used for on-premises Instana backend installations.
    @objc static func setup(key: String, reportingURL: URL? = nil, reportingType: ReportingType = .automaticAndManual) {
        // TODO: leave when current a session exists
        // Currently setup would be possible n times in one app lifecycle
        let config = InstanaConfiguration.default(key: key, reportingURL:  reportingURL)
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
    @objc static func markHTTP(_ url: URL, method: String) -> HTTPMarker {
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
    /// You can also trace the HTTP reponse size manually once the size has been determined via the URLSessionDelegate. (Must be called before finished) For example:
    ///
    ///       func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    ///            marker?.set(responseSize: Instana.Types.HTTPSize(task: task, transactionMetrics: metrics.transactionMetrics))
    ///       }
    ///
    /// - Parameters:
    ///   - request: URLRequest of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    @objc static func markHTTP(_ request: URLRequest) -> HTTPMarker {
        let delegate = Instana.current?.monitors.http
        let url = request.url ?? URL(string: "http://instana-invalid")!
        return HTTPMarker(url: url, method: request.httpMethod ?? "invalid", trigger: .manual, delegate: delegate)
    }
}
