//  Created by Nikola Lajic on 12/25/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

protocol HTTPMarkerDelegate: class {
    func finalized(marker: HTTPMarker)
}

/// Remote call markers are used to track remote calls.

@objc public class HTTPMarker: NSObject {
    enum State {
        case started, failed(error: Error), finished(responseCode: Int), canceled
    }
    enum Trigger {
        case manual, automatic
    }
    let url: URL
    let method: String
    let trigger: Trigger
    let requestSize: Instana.Types.Bytes
    let startTime: Instana.Types.Milliseconds
    private(set) var responseSize: Instana.Types.Bytes = 0
    private var endTime: Instana.Types.Milliseconds?
    private(set) var state: State = .started
    private weak var delegate: HTTPMarkerDelegate?
    
    init(url: URL, method: String, trigger: Trigger = .automatic, requestSize: Instana.Types.Bytes = 0, delegate: HTTPMarkerDelegate?) {
        self.startTime = Date().millisecondsSince1970
        self.url = url
        self.method = method
        self.delegate = delegate
        self.trigger = trigger
        self.requestSize = requestSize
    }
}

extension HTTPMarker {

    /// Invoke this method after the request has successfuly finished.
    ///
    /// - Parameters:
    ///   - responseCode: Usually a HTTP status code.
    ///   - responseSize: Optional, size of the response.
    @objc public func ended(responseCode: Int, responseSize: Instana.Types.Bytes = 0) {
        guard case .started = state else { return }
        state = .finished(responseCode: responseCode)
        self.responseSize = responseSize
        endTime = Date().millisecondsSince1970
        delegate?.finalized(marker: self)
    }
    
    /// Invoke this method after the request has failed to finish.
    ///
    /// - Parameters:
    ///   - error: Error that explains what happened.
    ///   - responseSize: Optional, size of the response.
    @objc public func ended(error: Error, responseSize: Instana.Types.Bytes = 0) {
        guard case .started = state else { return }
        state = .failed(error: error)
        self.responseSize = responseSize
        endTime = Date().millisecondsSince1970
        delegate?.finalized(marker: self)
    }
    
    /// Invoke this method if the reuqest has been canceled before completion.
    @objc public func canceled() {
        guard case .started = state else { return }
        state = .canceled
        endTime = Date().millisecondsSince1970
        delegate?.finalized(marker: self)
    }

    ///
    /// Duration of the request. Available after one of the completion method has been invoked.
    var duration: Instana.Types.Milliseconds {
        guard let endTime = self.endTime else { return 0 }
        return Instana.Types.Milliseconds(endTime - startTime)
    }
}

extension HTTPMarker {
    func createBeacon() -> Beacon {
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

        return HTTPBeacon(timestamp: startTime,
                         duration: duration,
                         method: method,
                         url: url,
                         responseCode: responseCode ?? -1,
                         requestSize: requestSize,
                         responseSize: responseSize,
                         result: result)
    }
}
