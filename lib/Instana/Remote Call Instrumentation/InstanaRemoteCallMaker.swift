//  Created by Nikola Lajic on 12/25/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

protocol InstanaRemoteCallMarkerDelegate: class {
    func marker(_ marker: InstanaRemoteCallMarker, enededWith responseCode: Int)
    func marker(_ marker: InstanaRemoteCallMarker, enededWith error: Error)
    func markerCanceled(_ marker: InstanaRemoteCallMarker)
}

@objc public class InstanaRemoteCallMarker: NSObject {
    enum State {
        case started, failed(error: Error), finished(responseCode: Int), canceled
    }
    enum Trigger {
        case manual, automatic
    }
    let url: String
    let method: String
    let id = UUID().uuidString
    let trigger: Trigger
    public let startTime: Instana.Types.UTCTimestamp
    private var endTime: Instana.Types.UTCTimestamp?
    private(set) var state: State = .started
    private weak var delegate: InstanaRemoteCallMarkerDelegate?
    
    init(url: String, method: String, trigger: Trigger = .automatic, delegate: InstanaRemoteCallMarkerDelegate) {
        startTime = Date().timeIntervalSince1970
        self.url = url
        self.method = method
        self.delegate = delegate
        self.trigger = trigger
    }
    
    convenience init(task: URLSessionTask, trigger: Trigger = .automatic, delegate: InstanaRemoteCallMarkerDelegate) {
        self.init(url: task.originalRequest?.url?.absoluteString ?? "", method: task.originalRequest?.httpMethod ?? "", delegate: delegate)
    }
}

extension InstanaRemoteCallMarker {
    @objc public var headers: [String: String] {
        get {
            return [:]
        }
    }
    
    @objc public func endedWith(responseCode: Int) {
        state = .finished(responseCode: responseCode)
        endTime = Date().timeIntervalSince1970
        delegate?.marker(self, enededWith: responseCode)
    }
    
    @objc public func endedWith(error: Error) {
        state = .failed(error: error)
        endTime = Date().timeIntervalSince1970
        delegate?.marker(self, enededWith: error)
    }
    
    @objc public func canceled() {
        state = .canceled
        endTime = Date().timeIntervalSince1970
        delegate?.markerCanceled(self)
    }
    
    @objc public func duration() -> Instana.Types.Milliseconds {
        guard let endTime = endTime else { return 0 }
        return Instana.Types.Milliseconds(endTime - startTime)
    }
}

extension InstanaRemoteCallMarker {
    func event() -> InstanaEvent {
        let result: String
        var responseCode: Int? = nil
        
        switch state {
        case .started:
            result = "started"
        case .canceled:
            result = "canceled"
        case .finished(let rc):
            result = "finished"
            responseCode = rc
        case .failed(let error):
            result = String(describing: error)
        }

        return InstanaRemoteCallEvent(timestamp: startTime, duration: duration(), method: method, url: url, responseCode: responseCode ?? -1, result: result)
    }
}
