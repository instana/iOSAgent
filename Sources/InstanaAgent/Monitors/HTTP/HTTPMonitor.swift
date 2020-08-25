import Foundation

class HTTPMonitor {
    private let installer: (AnyClass) -> Bool
    private let uninstaller: (AnyClass) -> Void
    private let reporter: Reporter
    private let session: InstanaSession

    init(_ session: InstanaSession,
         installer: @escaping (AnyClass) -> Bool = URLProtocol.registerClass,
         uninstaller: @escaping (AnyClass) -> Void = URLProtocol.unregisterClass,
         reporter: Reporter) {
        self.session = session
        self.installer = installer
        self.uninstaller = uninstaller
        self.reporter = reporter
        IgnoreURLHandler.exactURLs.insert(session.configuration.reportingURL)
        IgnoreURLHandler.exactURLs.formUnion(IgnoredURLs.excludedURLs)
        IgnoreURLHandler.ignore(patterns: IgnoredURLs.excludedPatterns)
        switch session.configuration.httpCaptureConfig {
        case .automatic:
            install()
        case .manual, .none:
            deinstall()
        }
    }

    func install() {
        InstanaURLProtocol.install
        InstanaURLProtocol.mode = .enabled
        _ = installer(InstanaURLProtocol.self)
    }

    func deinstall() {
        uninstaller(InstanaURLProtocol.self)
        InstanaURLProtocol.deinstall()
        InstanaURLProtocol.mode = .disabled
    }
}

extension HTTPMonitor {
    func mark(_ request: URLRequest) throws -> HTTPMarker {
        guard let url = request.url, let method = request.httpMethod else {
            throw InstanaError.invalidRequest
        }
        return HTTPMarker(url: url, method: method, trigger: .automatic, delegate: self)
    }

    func shouldReport(_ marker: HTTPMarker) -> Bool {
        switch session.configuration.httpCaptureConfig {
        case .automatic: return marker.trigger == .automatic
        case .manual: return marker.trigger == .manual
        case .none: return false
        }
    }
}

extension HTTPMonitor: HTTPMarkerDelegate {
    func httpMarkerDidFinish(_ marker: HTTPMarker) {
        guard shouldReport(marker) else { return }
        marker.viewName = marker.viewName ?? session.propertyHandler.properties.viewNameForCurrentAppState
        reporter.submit(marker.createBeacon())
    }
}
