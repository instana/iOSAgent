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
    
    @objc public func install(in configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
    }
    
    @objc public func markCall(to url: String, method: String) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(url: url, method: method, trigger: .manual, delegate: self)
    }
}

extension InstanaRemoteCallInstrumentation {
    func install() {
        URLProtocol.registerClass(InstanaURLProtocol.self)
    }
    
    func uninstall() {
        URLProtocol.unregisterClass(InstanaURLProtocol.self)
    }
    
    func markAutomaticCall(to url: String, method: String) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(url: url, method: method, trigger: .automatic, delegate: self)
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
    func marker(_ marker: InstanaRemoteCallMarker, enededWith responseCode: Int) {
        guard shouldReport(marker: marker) else { return }
        Instana.events.submit(event: marker.event())
    }
    
    func marker(_ marker: InstanaRemoteCallMarker, enededWith error: Error) {
        guard shouldReport(marker: marker) else { return }
        Instana.events.submit(event: marker.event())
    }
    
    func markerCanceled(_ marker: InstanaRemoteCallMarker) {
        guard shouldReport(marker: marker) else { return }
        Instana.events.submit(event: marker.event())
    }
}
