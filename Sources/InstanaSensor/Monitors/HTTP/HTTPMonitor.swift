//  Created by Nikola Lajic on 12/12/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

class HTTPMonitor {

    private let installer: (AnyClass) -> Bool
    private let uninstaller: (AnyClass) -> Void
    private let reporter: Reporter
    private let environment: InstanaEnvironment

    init(_ environment: InstanaEnvironment,
         installer: @escaping (AnyClass) -> Bool = URLProtocol.registerClass,
         uninstaller: @escaping (AnyClass) -> Void = URLProtocol.unregisterClass,
         reporter: Reporter) {
        self.environment = environment
        self.installer = installer
        self.uninstaller = uninstaller
        self.reporter = reporter

        switch environment.configuration.reportingType {
        case .automaticAndManual, .automatic:
            install()
        case .manual, .none:
            deinstall()
        }
    }

    func install() {
        InstanaURLProtocol.install()
        InstanaURLProtocol.mode = .enabled
        _ = installer(InstanaURLProtocol.self)
    }

    func deinstall() {
        InstanaURLProtocol.deinstall()
        InstanaURLProtocol.mode = .disabled
        uninstaller(InstanaURLProtocol.self)
    }
}

extension HTTPMonitor {

    func mark(_ request: URLRequest) throws -> HTTPMarker {
        debugAssert((request.url != nil), "URLRequest URL must not be nil")
        guard let url = request.url, let method = request.httpMethod else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Invalid URLRequest")
        }
        return HTTPMarker(url: url,
                          method: method,
                          trigger: .automatic,
                          delegate: self)
    }

    func mark(_ url: URL, method: String, size: Instana.Types.HTTPSize) throws -> HTTPMarker {
        return HTTPMarker(url: url,
                          method: method,
                          trigger: .automatic,
                          delegate: self)
    }
    
    private func shouldReport(marker: HTTPMarker) -> Bool {
        switch environment.configuration.reportingType {
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
