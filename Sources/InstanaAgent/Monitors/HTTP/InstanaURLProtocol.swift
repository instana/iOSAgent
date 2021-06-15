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
    private lazy var session: URLSession = {
        URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()

    private(set) lazy var sessionConfiguration: URLSessionConfiguration = { .default }()
    var marker: HTTPMarker?
    private var incomingTask: URLSessionTask?
    let markerQueue = DispatchQueue(label: "com.instana.ios.agent.InstanaURLProtocol", qos: .default)

    convenience init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        guard let request = task.currentRequest else { self.init(); return }
        self.init(request: request, cachedResponse: cachedResponse, client: client)
        if let session = task.internalSession {
            incomingTask = task
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
        guard let session = incomingTask?.internalSession else { return true }
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
            if #available(iOS 13.0, *), incomingTask is URLSessionWebSocketTask {
                return session.webSocketTask(with: request).resume()
            }
            if request.httpBodyStream != nil {
                return session.uploadTask(withStreamedRequest: request).resume()
            }

            switch incomingTask {
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
            session.invalidateAndCancel()
            if let marker = marker, case .started = marker.state { marker.cancel() }
        }
    }
}

extension InstanaURLProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        completionHandler(incomingTask?.currentRequest?.httpBodyStream)
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

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        markerQueue.sync {
            marker?.set(responseSize: HTTPMarker.Size(response: task.response ?? URLResponse(), transactionMetrics: metrics.transactionMetrics))
        }
    }
}

extension InstanaURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let incomingSession = incomingTask?.internalSession,
           let delegate = incomingSession.delegate,
           delegate.responds(to: #selector(urlSession(_ :didReceive:completionHandler:))) {
            delegate.urlSession?(incomingSession, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let incomingSession = incomingTask?.internalSession,
           let delegate = incomingSession.delegate as? URLSessionDataDelegate,
           delegate.responds(to: #selector(urlSession(_ :task:didReceive:completionHandler:))) {
            delegate.urlSession?(incomingSession, task: task, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        markerQueue.sync {
            marker?.set(responseSize: HTTPMarker.Size(response))
            marker?.finish(response: response, error: nil)
            marker = try? Instana.current?.monitors.http?.mark(request)
            completionHandler(request)
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
