//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import WebKit

class InstanaURLProtocol: URLProtocol {
    enum Mode {
        case enabled, disabled
    }

    static var mode: Mode = .disabled
    private(set) lazy var sessionConfiguration: URLSessionConfiguration = {
        .default
    }()

    private lazy var session: URLSession = {
        URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    var marker: HTTPMarker?
    private(set) weak var originalTask: URLSessionTask?
    let markerQueue = DispatchQueue(label: "com.instana.ios.agent.InstanaURLProtocol", qos: .default)

    convenience init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        guard let request = task.currentRequest else { self.init(); return }
        self.init(request: request, cachedResponse: cachedResponse, client: client)
        if let session = task.internalSession {
            originalTask = task
            sessionConfiguration = session.configuration
            // Use the sessionConfiguration set by the incoming task for the forwading -
            // Exclude "us" from the protocolClasses to avoid "monitoring the monitor"
            sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter { $0 !== InstanaURLProtocol.self }
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard mode == .enabled else { return false }
        guard let url = request.url, let scheme = url.scheme, !IgnoreURLHandler.shouldIgnore(url) else { return false }
        return ["http", "https"].contains(scheme)
    }

    private var canMark: Bool {
        guard let session = originalTask?.internalSession else { return true }
        return !IgnoreURLHandler.urlSessions.contains(session)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        markerQueue.sync {
            if InstanaURLProtocol.mode == .enabled, canMark {
                marker = try? Instana.current?.monitors.http?.mark(request)
            }
            if #available(iOS 13.0, *), originalTask is URLSessionWebSocketTask {
                return session.webSocketTask(with: request).resume()
            }
            if request.httpBodyStream != nil {
                return session.uploadTask(withStreamedRequest: request).resume()
            }

            switch originalTask {
            case is URLSessionUploadTask:
                if let data = request.httpBody {
                    session.uploadTask(with: request, from: data).resume()
                } else {
                    session.dataTask(with: request).resume()
                }
            default:
                session.dataTask(with: request).resume()
            }
        }
    }

    override func stopLoading() {
        markerQueue.sync {
            if let marker = marker, case .started = marker.state {
                marker.cancel()
            }
            session.finishTasksAndInvalidate()
        }
    }
}

extension InstanaURLProtocol {
    func dispatch(on queue: DispatchQueue?, code: @escaping () -> Void) {
        if let queue = queue {
            queue.async(execute: code)
        } else {
            code()
        }
    }
}

extension InstanaURLProtocol: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let marker = marker, case .canceled = marker.state, let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, didBecomeInvalidWithError: error)
            }
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate,
            delegate.responds(to: #selector(urlSession(_:didReceive:completionHandler:))) {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, didReceive: challenge, completionHandler: completionHandler)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    @available(macOS 11.0, iOS 11, *)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSessionDidFinishEvents?(forBackgroundURLSession: originalSession)
            }
        }
    }
}

extension InstanaURLProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate,
            delegate.responds(to: #selector(urlSession(_:task:willBeginDelayedRequest:completionHandler:))) {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, task: originalTask, willBeginDelayedRequest: request, completionHandler: completionHandler)
            }
        } else {
            completionHandler(.continueLoading, nil)
        }
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, taskIsWaitingForConnectivity: originalTask)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        markerQueue.sync {
            marker?.finish(response: response, error: nil)
            marker = try? Instana.current?.monitors.http?.mark(request)
            if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate,
                delegate.responds(to: #selector(urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:))) {
                dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                    delegate.urlSession?(originalSession, task: originalTask, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
                }
            } else {
                completionHandler(request)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate,
            delegate.responds(to: #selector(urlSession(_:task:didReceive:completionHandler:))) {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, task: originalTask, didReceive: challenge, completionHandler: completionHandler)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate,
            delegate.responds(to: #selector(urlSession(_:task:needNewBodyStream:))) {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, task: originalTask, needNewBodyStream: completionHandler)
            }
        } else {
            completionHandler(originalTask?.currentRequest?.httpBodyStream)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let originalTask = originalTask, let originalSession = originalTask.internalSession, let delegate = originalSession.delegate as? URLSessionTaskDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, task: originalTask, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        markerQueue.sync {
            if let response = task.response {
                marker?.set(responseSize: .init(response: response, transactionMetrics: metrics.transactionMetrics))
            }
        }
//     Not needed to forward to the client - will be called without forwarding to the client - Forwarding would call the delegate twice and might cause unexpected results
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        markerQueue.sync {
            marker?.finish(response: task.response, error: error)
        }
    }
}

extension InstanaURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate as? URLSessionDataDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, dataTask: dataTask, didBecome: downloadTask)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionDataDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, dataTask: dataTask, didBecome: streamTask)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionDataDelegate,
            delegate.responds(to: #selector(urlSession(_:dataTask:willCacheResponse:completionHandler:))) {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
            }
        } else {
            var doCache = proposedResponse.storagePolicy != .notAllowed
            doCache = doCache && originalTask?.internalSession?.configuration.requestCachePolicy != .reloadIgnoringLocalCacheData
            doCache = doCache && originalTask?.internalSession?.configuration.requestCachePolicy != .reloadIgnoringLocalAndRemoteCacheData
            completionHandler(doCache ? proposedResponse : nil)
        }
    }
}

extension InstanaURLProtocol: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionDownloadDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession(originalSession, downloadTask: downloadTask, didFinishDownloadingTo: location)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionDownloadDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionDownloadDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
            }
        }
    }
}

extension InstanaURLProtocol: URLSessionStreamDelegate {
    func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate as? URLSessionStreamDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, readClosedFor: streamTask)
            }
        }
    }

    func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate as? URLSessionStreamDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, writeClosedFor: streamTask)
            }
        }
    }

    func urlSession(_ session: URLSession, betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate as? URLSessionStreamDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, betterRouteDiscoveredFor: streamTask)
            }
        }
    }

    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecome inputStream: InputStream, outputStream: OutputStream) {
        if let originalSession = originalTask?.internalSession, let delegate = originalSession.delegate as? URLSessionStreamDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, streamTask: streamTask, didBecome: inputStream, outputStream: outputStream)
            }
        }
    }
}

@available(iOS 13.0, *)
extension InstanaURLProtocol: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionWebSocketDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
            }
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        if let originalSession = originalTask?.internalSession,
            let delegate = originalSession.delegate as? URLSessionWebSocketDelegate {
            dispatch(on: originalSession.delegateQueue.underlyingQueue) {
                delegate.urlSession?(originalSession, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
            }
        }
    }
}

extension URLSessionConfiguration {
    func registerInstanaURLProtocol() {
        if let classes = protocolClasses, !classes.contains(where: { $0 == InstanaURLProtocol.self }) {
            protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
            if !URLSessionConfiguration.all.contains(self) {
                URLSessionConfiguration.all.append(self)
            }
        }
    }

    private static let lock = NSLock()
    private static var _unsafe_allSessionConfigs = [URLSessionConfiguration]()
    static var all: [URLSessionConfiguration] {
        // swiftlint:disable:next implicit_getter
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _unsafe_allSessionConfigs
        }
        set {
            lock.lock()
            _unsafe_allSessionConfigs = newValue
            lock.unlock()
        }
    }

    static func removeAllInstanaURLProtocol() {
        all.forEach { $0.protocolClasses?.removeAll(where: { (protocolClass) -> Bool in
            protocolClass == InstanaURLProtocol.self
        }) }
        URLSessionConfiguration.all.removeAll()
    }

    func removeInstanaURLProtocol() {
        protocolClasses = protocolClasses?.filter { $0 !== InstanaURLProtocol.self }
        URLSessionConfiguration.all.removeAll(where: { $0 == self })
    }
}

extension InstanaURLProtocol {
    // We do some swi**ling to inject our InstanaURLProtocol to all custom sessions automatically
    // Will be called only once by using a static let
    static let install: () = {
        prepareURLSessions
    }()

    static func deinstall() {
        URLSessionConfiguration.removeAllInstanaURLProtocol()
    }

    // Will be called only once by using a static let
    static let prepareURLSessions: () = {
        let originalSelector = #selector(URLSession.init(configuration:delegate:delegateQueue:))
        guard let originalMethod = class_getClassMethod(URLSession.self, originalSelector) else { return }

        let originalImp = method_getImplementation(originalMethod)

        let newFunction: @convention(block) (AnyObject, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession
        newFunction = { obj, configuration, delegate, queue in
            var canRegister = true
            if let delegate = delegate, delegate is URLProtocol {
                canRegister = false
            }
            if canRegister {
                configuration.registerInstanaURLProtocol()
            }
            typealias OriginalFunction = @convention(c) (AnyObject, Selector, URLSessionConfiguration, URLSessionDelegate?, OperationQueue?) -> URLSession
            let callback = unsafeBitCast(originalImp, to: OriginalFunction.self)
            return callback(obj, originalSelector, configuration, delegate, queue)
        }
        method_setImplementation(originalMethod, imp_implementationWithBlock(newFunction))
    }()
}

private extension URLSessionTask {
    var internalSession: URLSession? {
        let selector = NSSelectorFromString("session")
        guard responds(to: selector) else { return nil }
        guard let implementation = type(of: self).instanceMethod(for: selector) else { return nil }
        typealias FunctionSignature = @convention(c) (AnyObject, Selector) -> URLSession?
        let sessionMethod = unsafeBitCast(implementation, to: FunctionSignature.self)
        return sessionMethod(self, selector)
    }
}
