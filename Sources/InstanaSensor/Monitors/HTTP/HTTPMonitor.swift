//  Created by Nikola Lajic on 12/12/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

class HTTPMonitor {

    private let installer: (AnyClass) -> Bool
    private let uninstaller: (AnyClass) -> Void
    private let reporter: Reporter
    private let configuration: InstanaConfiguration

    init(_ configuration: InstanaConfiguration,
         installer: @escaping (AnyClass) -> Bool = URLProtocol.registerClass,
         uninstaller: @escaping (AnyClass) -> Void = URLProtocol.unregisterClass,
         reporter: Reporter) {
        self.configuration = configuration
        self.installer = installer
        self.uninstaller = uninstaller
        self.reporter = reporter
        determineReporting(reportingType: configuration.reportingType)
    }

    /// Determines what types of calls will be reported to the Instana backend.
    private func determineReporting(reportingType: ReportingType) {
        switch reportingType {
        case .automaticAndManual, .automatic:
            install()
        case .manual, .none:
            uninstall()
        }
    }

    func track(_ configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
    }
}

extension HTTPMonitor {
    func install() {
        _ = installer(InstanaURLProtocol.self)
    }
    
    func uninstall() {
        uninstaller(InstanaURLProtocol.self)
    }
    
    func mark(_ request: URLRequest) throws -> HTTPMarker {
        debugAssert((request.url != nil), "URLRequest URL must not be nil")
        guard let url = request.url, let method = request.httpMethod else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Invalid URLRequest")
        }
        return HTTPMarker(url: url,
                          method: method,
                          trigger: .automatic,
                          requestSize: Instana.Types.Bytes(request.httpBody?.count ?? 0),
                          delegate: self)
    }

    func mark(_ url: URL, method: String, size: Instana.Types.Bytes = 0) throws -> HTTPMarker {
        return HTTPMarker(url: url,
                          method: method,
                          trigger: .automatic,
                          requestSize: size,
                          delegate: self)
    }
    
    private func shouldReport(marker: HTTPMarker) -> Bool {
        switch configuration.reportingType {
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
        reporter.submit(marker.createBeacon())
    }
}
