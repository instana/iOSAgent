//  Created by Nikola Lajic on 12/12/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc public class InstanaRemoteCallInstrumentation: NSObject {
    @objc public enum ReportingType: Int {
        case automaticAndManual, automatic, manual
    }
    @objc public var type: ReportingType = .automaticAndManual // TODO: implement actual check
    // TODO: install in observer?
    
    @objc public func install(in configuration: URLSessionConfiguration) {
        configuration.protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
    }
    
    @objc public func markCall(to url: String, method: String) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(url: url, method: method, delegate: self)
    }
}

extension InstanaRemoteCallInstrumentation {
    func install() {
        URLProtocol.registerClass(InstanaURLProtocol.self)
    }
    
    func uninstall() {
        URLProtocol.unregisterClass(InstanaURLProtocol.self)
    }
    
    func markCall(with task: URLSessionTask) -> InstanaRemoteCallMarker {
        return InstanaRemoteCallMarker(task: task, delegate: self)
    }
}

extension InstanaRemoteCallInstrumentation: InstanaRemoteCallMarkerDelegate {
    func marker(_ marker: InstanaRemoteCallMarker, enededWith responseCode: Int) {
        Instana.events.submit(event: marker.event())
    }
    
    func marker(_ marker: InstanaRemoteCallMarker, enededWith error: Error) {
        Instana.events.submit(event: marker.event())
    }
    
    func markerCanceled(_ marker: InstanaRemoteCallMarker) {
        Instana.events.submit(event: marker.event())
    }
}
