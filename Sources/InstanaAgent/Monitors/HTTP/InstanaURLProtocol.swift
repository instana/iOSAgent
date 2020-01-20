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

    convenience init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        self.init(request: task.originalRequest!, cachedResponse: cachedResponse, client: client)
        if let session = task.internalSession {
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

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard InstanaURLProtocol.mode == .enabled else { return }
        marker = try? Instana.current?.monitors.http?.mark(request)
        let task = session.dataTask(with: request)
        task.resume()
    }

    override func stopLoading() {
        session.invalidateAndCancel()
        if let marker = marker, case .started = marker.state { marker.cancel() }
    }
}

extension InstanaURLProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        marker?.finish(response: task.response, error: error)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        marker?.set(responseSize: HTTPMarker.Size(response: task.response ?? URLResponse(), transactionMetrics: metrics.transactionMetrics))
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

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        marker?.set(responseSize: HTTPMarker.Size(response))
        marker?.finish(response: response, error: nil)
        marker = try? Instana.current?.monitors.http?.mark(request)
        completionHandler(request)
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
        set {
            lock.lock()
            _unsafe_allSessionConfigs = newValue
            lock.unlock()
        }
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _unsafe_allSessionConfigs
        }
    }

    static func removeInstanaURLProtocol() {
        all.forEach { $0.protocolClasses?.removeAll(where: { (protocolClass) -> Bool in
            protocolClass == InstanaURLProtocol.self
        }) }
        URLSessionConfiguration.all.removeAll()
    }
}

extension InstanaURLProtocol {
    // We do some swi**ling to inject our InstanaURLProtocol to all custom sessions automatically
    // Will be called only once by using a static let
    static let install: () = {
        prepareWebView
        prepareURLSessions
    }()

    static func deinstall() {
        URLSessionConfiguration.removeInstanaURLProtocol()
    }

    // Will be called only once by using a static let
    static let prepareWebView: () = {
        guard let something = WKWebView().value(forKey: "browsingContextController") as? NSObject else { return }
        let selector = NSSelectorFromString("registerSchemeForCustomProtocol:")
        if type(of: something).responds(to: selector) {
            type(of: something).perform(selector, with: "http")
            type(of: something).perform(selector, with: "https")
        }
    }()

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
