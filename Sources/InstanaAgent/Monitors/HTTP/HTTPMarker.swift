//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

protocol HTTPMarkerDelegate: AnyObject {
    func httpMarkerDidFinish(_ marker: HTTPMarker)
}

@objc public class HTTPCaptureResult: NSObject {
    let statusCode: Int
    let backendTracingID: String?
    let responseSize: HTTPMarker.Size?
    let error: Error?
    @objc public init(statusCode: Int,
                      backendTracingID: String? = nil,
                      responseSize: HTTPMarker.Size? = nil,
                      error: Error? = nil) {
        self.statusCode = statusCode
        self.backendTracingID = backendTracingID
        self.responseSize = responseSize
        self.error = error
    }
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
    var viewName: String?
    private(set) var backendTracingID: String?
    private(set) var responseSize: HTTPMarker.Size?
    private var endTime: Instana.Types.Milliseconds?
    private(set) var state: State = .started
    private weak var delegate: HTTPMarkerDelegate?

    init(url: URL, method: String, trigger: Trigger, delegate: HTTPMarkerDelegate?, viewName: String? = nil) {
        startTime = Date().millisecondsSince1970
        self.url = url
        self.method = method
        self.delegate = delegate
        self.trigger = trigger
        self.viewName = viewName
    }

    /// Invoke this method when the reponse size has been determined.
    ///
    /// - Parameters:
    ///   - responseSize: Size of the response.
    ///
    /// Note: You must make sure to trigger `set(responseSize:` before calling the finish or cancel method
    @objc public func set(responseSize: HTTPMarker.Size) {
        guard case .started = state else { return }
        self.responseSize = responseSize
    }

    /// Invoke this method after the request has been completed.
    ///
    /// - Parameters:
    ///   - response: Optional URLResponse when the request has been completed.
    ///   - error: Optional Error
    ///
    /// Note: Make sure you don't call any methods on this HTTPMarker after you called finish
    @objc public func finish(response: URLResponse?, error: Error?) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 400
        let size = response != nil ? HTTPMarker.Size(response!) : nil
        let result = HTTPCaptureResult(statusCode: statusCode,
                                       backendTracingID: response?.backendTracingID,
                                       responseSize: responseSize ?? size,
                                       error: error)
        finish(result)
    }

    /// Invoke this method after the request has been completed.
    ///
    /// - Parameters:
    ///   - result: Pass the HTTPCaptureResult when the request has been completed.
    ///   - error: Optional Error
    ///
    /// Note: Make sure you don't call any methods on this HTTPMarker after you called finish
    @objc public func finish(_ result: HTTPCaptureResult) {
        guard case .started = state else { return }
        if let error = result.error {
            state = .failed(error: error)
        } else {
            state = .finished(responseCode: result.statusCode)
        }
        endTime = Date().millisecondsSince1970
        if let bid = result.backendTracingID {
            backendTracingID = bid
        }
        responseSize = result.responseSize
        delegate?.httpMarkerDidFinish(self)
    }

    /// Invoke this method if the request has been canceled before completion.
    /// Note: Make sure you don't call more methods on this HTTPMarker after you called canceled
    @objc public func cancel() {
        guard case .started = state else { return }
        state = .canceled
        endTime = Date().millisecondsSince1970
        delegate?.httpMarkerDidFinish(self)
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
        var error: Error?
        var responseCode: Int?

        switch state {
        case .started:
            break
        case .canceled:
            error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        case let .finished(code):
            responseCode = code
        case let .failed(theError):
            error = theError
        }

        return HTTPBeacon(timestamp: startTime,
                          duration: duration,
                          method: method,
                          url: url,
                          responseCode: responseCode ?? -1,
                          responseSize: responseSize,
                          error: error,
                          backendTracingID: backendTracingID,
                          viewName: viewName)
    }
}

extension HTTPMarker {
    @objc(HTTPSize) public class Size: NSObject {
        var headerBytes: Instana.Types.Bytes?
        var bodyBytes: Instana.Types.Bytes?
        var bodyBytesAfterDecoding: Instana.Types.Bytes?

        @objc public init(header: Instana.Types.Bytes = 0, body: Instana.Types.Bytes = 0, bodyAfterDecoding: Instana.Types.Bytes = 0) {
            super.init()
            headerBytes = header > 0 ? header : nil
            bodyBytes = body > 0 ? body : nil
            bodyBytesAfterDecoding = bodyAfterDecoding > 0 ? bodyAfterDecoding : nil
        }

        @objc public convenience init(response: URLResponse, transactionMetrics: [URLSessionTaskTransactionMetrics]?) {
            guard #available(iOS 13.0, *) else {
                self.init(response)
                return
            }
            guard let metrics = transactionMetrics else {
                self.init(response)
                return
            }
            if metrics.isEmpty {
                self.init(response)
                return
            }
            let headerBytes = metrics.map { $0.countOfResponseHeaderBytesReceived }.reduce(0, +)
            let bodyBytes = metrics.map { $0.countOfResponseBodyBytesReceived }.reduce(0, +)
            let bodyBytesAfterDecoding = metrics.map { $0.countOfResponseBodyBytesAfterDecoding }.reduce(0, +)
            self.init(header: headerBytes, body: bodyBytes, bodyAfterDecoding: bodyBytesAfterDecoding)
        }

        internal override init() {
            headerBytes = 0
            bodyBytes = 0
            bodyBytesAfterDecoding = 0
        }

        internal convenience init(_ response: URLResponse) {
            var headerBytes: Instana.Types.Bytes = 0
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields,
                let data = try? NSKeyedArchiver.archivedData(withRootObject: headerFields, requiringSecureCoding: false) {
                headerBytes = Instana.Types.Bytes(data.count)
            }
            self.init(header: headerBytes, body: response.expectedContentLength, bodyAfterDecoding: 0)
        }
    }
}
