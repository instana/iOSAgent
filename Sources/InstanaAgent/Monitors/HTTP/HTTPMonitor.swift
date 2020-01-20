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
        debugAssert(request.url != nil, "URLRequest URL must not be nil")
        guard let url = request.url, let method = request.httpMethod else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Invalid URLRequest")
        }
        let viewName = session.propertyHandler.properties.view
        return HTTPMarker(url: url, method: method, trigger: .automatic, delegate: self, viewName: viewName)
    }

    private func shouldReport(marker: HTTPMarker) -> Bool {
        switch session.configuration.httpCaptureConfig {
        case .automatic: return marker.trigger == .automatic
        case .manual: return marker.trigger == .manual
        case .none: return false
        }
    }
}

extension HTTPMonitor: HTTPMarkerDelegate {
    func httpMarkerDidFinish(_ marker: HTTPMarker) {
        guard shouldReport(marker: marker) else { return }
        reporter.submit(marker.createBeacon())
    }
}
