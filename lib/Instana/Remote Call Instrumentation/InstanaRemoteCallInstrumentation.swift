//  Created by Nikola Lajic on 12/12/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaRemoteCallInstrumentation: NSObject {
    @objc public enum ReportingType: Int {
        case automaticAndManual, automatic, manual, none
    }
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
    private let submit: InstanaEvents.Submitter
    private let networkConnectionType: () -> InstanaNetworkMonitor.ConnectionType?
    
    init(installer: @escaping (AnyClass) -> Bool = URLProtocol.registerClass,
         uninstaller: @escaping (AnyClass) -> Void = URLProtocol.unregisterClass,
         submitter: @escaping InstanaEvents.Submitter = Instana.events.submit(event:),
         networkConnectionType: @escaping () -> InstanaNetworkMonitor.ConnectionType? = { InstanaNetworkMonitor.shared.connectionType } ) {
        self.installer = installer
        self.uninstaller = uninstaller
        self.submit = submitter
        self.networkConnectionType = networkConnectionType
    }
    
    @objc public func install(in configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
    }
    
    @objc public func markCall(to url: String, method: String) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(url: url, method: method, trigger: .manual, connectionType: networkConnectionType(), delegate: self)
    }
}

extension InstanaRemoteCallInstrumentation {
    func install() {
        _ = installer(InstanaURLProtocol.self)
    }
    
    func uninstall() {
        uninstaller(InstanaURLProtocol.self)
    }
    
    func markCall(for request: URLRequest) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(url: request.url?.absoluteString ?? "",
                                       method: request.httpMethod ?? "",
                                       trigger: .automatic,
                                       requestSize: Instana.Types.Bytes(request.httpBody?.count ?? 0),
                                       connectionType: networkConnectionType(),
                                       delegate: self)
    }
    
    private func shouldReport(marker: InstanaRemoteCallMarker) -> Bool {
        switch reporting {
        case .automaticAndManual: return true
        case .automatic: return marker.trigger == .automatic
        case .manual: return marker.trigger == .manual
        case .none: return false
        }
    }
}

extension InstanaRemoteCallInstrumentation: InstanaRemoteCallMarkerDelegate {
    func finalized(marker: InstanaRemoteCallMarker) {
        guard shouldReport(marker: marker) else { return }
        submit(marker.event())
    }
}
