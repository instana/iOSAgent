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
    let startTime: Instana.Types.Milliseconds
    private(set) var responseSize: Instana.Types.HTTPSize?
    private var endTime: Instana.Types.Milliseconds?
    private(set) var state: State = .started
    private weak var delegate: HTTPMarkerDelegate?

    init(url: URL, method: String, trigger: Trigger = .automatic, delegate: HTTPMarkerDelegate?) {
        self.startTime = Date().millisecondsSince1970
        self.url = url
        self.method = method
        self.delegate = delegate
        self.trigger = trigger
    }
}

extension HTTPMarker {

    /// Invoke this method when the reponse size has been determined.
    ///
    /// - Parameters:
    ///   - responseSize: Size of the response.
    ///
    ///  Must be set before calling finished
    @objc public func set(responseSize: Instana.Types.HTTPSize) {
        self.responseSize = responseSize
    }

    /// Invoke this method after the request has successfuly finished.
    ///
    /// - Parameters:
    ///   - responseCode: Usually a HTTP status code.
    @objc public func finished(responseCode: Int) {
        guard case .started = state else { return }
        state = .finished(responseCode: responseCode)
        endTime = Date().millisecondsSince1970
        delegate?.finalized(marker: self)
    }
    
    /// Invoke this method after the request has failed to finish.
    ///
    /// - Parameters:
    ///   - error: Error that explains what happened.
    @objc public func finished(error: Error) {
        guard case .started = state else { return }
        state = .failed(error: error)
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
                         responseSize: responseSize,
                         result: result)
    }
}

extension HTTPMarker {
    @objc public class HTTPSize: NSObject {
        var headerBytes: Instana.Types.Bytes?
        var bodyBytes: Instana.Types.Bytes?
        var bodyBytesAfterDecoding: Instana.Types.Bytes?

        // Need multiple init because of ObjC interop
        @objc public override init() {
            super.init()
            self.headerBytes = nil
            self.bodyBytes = nil
            self.bodyBytesAfterDecoding = nil
        }

        @objc public init(header: Instana.Types.Bytes) {
            super.init()
            self.headerBytes = header
            self.bodyBytes = nil
            self.bodyBytesAfterDecoding = nil
        }

        @objc public init(header: Instana.Types.Bytes, body: Instana.Types.Bytes) {
            super.init()
            self.headerBytes = header
            self.bodyBytes = body
            self.bodyBytesAfterDecoding = nil
        }

        @objc public init(header: Instana.Types.Bytes, body: Instana.Types.Bytes, bodyAfterDecoding: Instana.Types.Bytes) {
            super.init()
            self.headerBytes = header
            self.bodyBytes = body
            self.bodyBytesAfterDecoding = bodyAfterDecoding
        }

        @objc public class func response(task: URLSessionTask, transactionMetrics: [URLSessionTaskTransactionMetrics]) -> HTTPSize {
            let size = HTTPSize()
            guard #available(iOS 13.0, *) else {
                if let headerFields = (task.response as? HTTPURLResponse)?.allHeaderFields {
                    size.headerBytes = Instana.Types.Bytes(NSKeyedArchiver.archivedData(withRootObject: headerFields).count)
                }
                size.bodyBytes = task.countOfBytesReceived
                return size
            }
            size.headerBytes = transactionMetrics.map {$0.countOfResponseHeaderBytesReceived}.reduce(0, +)
            size.bodyBytes = transactionMetrics.map{ $0.countOfResponseBodyBytesReceived}.reduce(0, +)
            size.bodyBytesAfterDecoding = transactionMetrics.map {$0.countOfResponseBodyBytesAfterDecoding}.reduce(0, +)
            return size
        }
    }
}
