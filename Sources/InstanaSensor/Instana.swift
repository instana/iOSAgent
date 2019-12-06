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
    private (set) lazy var monitors = Monitors(configuration, reporter: reporter)

    /// Object to manage and report Beacons.
    private (set) lazy var reporter = Reporter(configuration)

    /// A debugging console logger using levels
    let logger = InstanaLogger()

    /// The Session ID created on each app launch
    let sessionId = UUID().uuidString

    /// The current Instana configuration
    let configuration: InstanaConfiguration

    static var current = Instana(configuration: .default(key: ""))

    private init(configuration: InstanaConfiguration) {
        self.configuration = configuration
        super.init()
        assert(!configuration.reportingURL.absoluteString.isEmpty, "Instana Reporting URL must not be empty")
        if configuration.isValid {
            reporter.submit(SessionProfileBeacon(state: .start, sessionId: sessionId))
        }
    }
}

/// Public API methods
@objc public extension Instana {


    /// Optional reporting URL used for on-premises Instana backend installations.
    @objc class var reportingURL: URL { Instana.current.configuration.reportingURL }

    /// Instana key identifying your application.
    @objc class var key: String { Instana.current.configuration.key }

    /// Configures and sets up the Instana SDK with the default configuration.
    ///
    /// - Note: Should be called only once, as soon as posible. Preferablly in `application(_:, didFinishLaunchingWithOptions:)`
    /// - Parameters:
    ///   - key: Instana key identifying your application.
    ///   - reportingURL: Optional reporting URL used for on-premises Instana backend installations.
    @objc static func setup(key: String, reportingURL: URL? = nil, reportingType: ReportingType = .automaticAndManual) {
        let config = InstanaConfiguration.default(key: key, reportingURL:  reportingURL)
        Instana.current = Instana(configuration: config)
    }

    /// Adds a tracking URL protocol to the configuration.
    /// Calls made with a session created with this configuration are considered "automatic".
    ///
    /// - Note: Any custom `URLSessionConfiguration` must be monitored explicitly
    /// - Important: URLSession configuration can't be modified after initialization, so make sure to invoke this before creating the session.
    /// - Parameter configuration: URL session configuration to add the tracking protocol to.
    @objc static func monitor(_ configuration: URLSessionConfiguration) {
        Instana.current.monitors.http?.track(configuration)
    }

    /// Use this method to manually monitor remote calls that can't be tracked automatically.
    ///
    /// For example:
    ///
    ///     let marker = Instana.markHTTPCall(url, method: "GET")
    ///     URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if let error = error {
    ///             marker.ended(error: error)
    ///         }
    ///         else {
    ///             marker.ended(responseCode: (response as? HTTPURLResponse)?.statusCode ?? 200)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - url: URL of the call.
    ///   - method: Method of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    @objc class func markHTTP(_ url: URL, method: String) -> HTTPMarker {
        let delegate = Instana.current.monitors.http
        let networktype = Instana.current.monitors.network.connectionType
        return HTTPMarker(url: url, method: method, trigger: .manual, connectionType: networktype, delegate: delegate)
    }

    /// Use this method to manually monitor remote calls that can't be tracked automatically.
    ///
    /// For example:
    ///
    ///     let marker = Instana.markHTTP(urlRequest)
    ///     URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if let error = error {
    ///             marker.ended(error: error)
    ///         }
    ///         else {
    ///             marker.ended(responseCode: (response as? HTTPURLResponse)?.statusCode ?? 200)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - request: URLRequest of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    @objc class func markHTTP(_ request: URLRequest) -> HTTPMarker {
        let delegate = Instana.current.monitors.http
        let networktype = Instana.current.monitors.network.connectionType
        let url = request.url ?? URL(string: "http://instana-invalid")!
        return HTTPMarker(url: url, method: request.httpMethod ?? "invalid", trigger: .manual, requestSize: Instana.Types.Bytes(request.httpBody?.count ?? 0), connectionType: networktype, delegate: delegate)
    }
}
