//  Created by Nikola Lajic on 12/12/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

/// Object acting as a namespace for configuring and using remote call instrumentation.
@objc public class HTTPMonitor: NSObject {
    
    /// An enum insted of option list because of Obj-C support.
    @objc public enum ReportingType: Int {
        /// Both automatic and manual calls will be reported
        case automaticAndManual
        /// Only automatic calls will be reported
        case automatic
        /// Only manual calls will be reported
        case manual
        /// Ignore all calls
        case none
    }
    
    /// Determines what types of calls will be reported to the Instana backend.
    @objc public var reporting: ReportingType = .none {
        didSet {
            switch reporting {
            case .automaticAndManual, .automatic:
                install()
            case .manual, .none:
                uninstall()
            }
        }
    }
    
    private let installer: (AnyClass) -> Bool
    private let uninstaller: (AnyClass) -> Void
    private let submitter: EventReporter.Submitter
    private let networkConnectionType: () -> InstanaNetworkMonitor.ConnectionType?
    
    init(installer: @escaping (AnyClass) -> Bool = URLProtocol.registerClass,
         uninstaller: @escaping (AnyClass) -> Void = URLProtocol.unregisterClass,
         submitter: @escaping EventReporter.Submitter = Instana.eventReporter.submit(_:),
         networkConnectionType: @escaping () -> InstanaNetworkMonitor.ConnectionType? = { InstanaNetworkMonitor.shared.connectionType } ) {
        self.installer = installer
        self.uninstaller = uninstaller
        self.submitter = submitter
        self.networkConnectionType = networkConnectionType
    }
    
    /// Adds a tracking URL protocol to the configuration.
    ///
    /// Calls made with a session created with this configuration are considered "automatic".
    /// - Important: URLSession configuration can't be modified after initialization, so make sure to invoke this before creating the session.
    /// - Parameter configuration: URL session configuration to add the tracking protocol to.
    @objc public func install(in configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
    }
    
    /// Use this method to manually instrument remote calls that can't be instrument automatically.
    /// For example, if you are not URLSession, or want to customize the response.
    ///
    ///     let marker = Instana.remoteCallInstrumentation.markCall(to: url.absoluteString, method: "GET")
    ///     URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if let error = error {
    ///             marker.endedWith(error: error)
    ///         }
    ///         else {
    ///             marker.endedWith(responseCode: (response as? HTTPURLResponse)?.statusCode ?? 200)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - url: URL of the call.
    ///   - method: Method of the call.
    /// - Returns: A remote call marker which is used to notify the SDK of call results by invoking one of its completion methods.
    @objc public func markCall(to url: String, method: String) -> HTTPMarker {
        return HTTPMarker(url: url, method: method, trigger: .manual, connectionType: networkConnectionType(), delegate: self)
    }
}

extension HTTPMonitor {
    func install() {
        _ = installer(InstanaURLProtocol.self)
    }
    
    func uninstall() {
        uninstaller(InstanaURLProtocol.self)
    }
    
    func markCall(for request: URLRequest) -> HTTPMarker {
        return HTTPMarker(url: request.url?.absoluteString ?? "",
                                       method: request.httpMethod ?? "",
                                       trigger: .automatic,
                                       requestSize: Instana.Types.Bytes(request.httpBody?.count ?? 0),
                                       connectionType: networkConnectionType(),
                                       delegate: self)
    }
    
    private func shouldReport(marker: HTTPMarker) -> Bool {
        switch reporting {
        case .automaticAndManual: return true
        case .automatic: return marker.trigger == .automatic
        case .manual: return marker.trigger == .manual
        case .none: return false
        }
    }
}

extension HTTPMonitor: HTTPMarkerDelegate {
    func finalized(marker: HTTPMarker) {
        guard shouldReport(marker: marker) else { return }
        submitter(marker.createEvent())
    }
}
