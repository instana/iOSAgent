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
        if let internalSession = task.internalSession() {
            sessionConfiguration = internalSession.configuration
            sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter { $0 !== InstanaURLProtocol.self }
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard mode == .enabled else { return false }
        guard let url = request.url, let scheme = url.scheme else { return false }
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
        if let marker = marker, case .started = marker.state { marker.canceled() }
    }
}

extension InstanaURLProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let response = task.response as? HTTPURLResponse
        if let backendTracingID = task.response?.backendTracingID {
            marker?.set(backendTracingID: backendTracingID)
        }
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            marker?.finished(error: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
            marker?.finished(responseCode: response?.statusCode ?? 0)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        marker?.set(responseSize: Instana.Types.HTTPSize.size(for: task.response ?? URLResponse(), transactionMetrics: metrics.transactionMetrics))
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
        if let backendTracingID = response.backendTracingID {
            marker?.set(backendTracingID: backendTracingID)
        }
        marker?.set(responseSize: Instana.Types.HTTPSize.size(response: response))
        marker?.finished(responseCode: response.statusCode)
        marker = try? Instana.current?.monitors.http?.mark(request)
        completionHandler(request)
    }
}

extension URLSessionConfiguration {
    func registerInstanaURLProtocol() {
        if let classes = protocolClasses, !classes.contains(where: { $0 == InstanaURLProtocol.self }) {
            protocolClasses?.insert(InstanaURLProtocol.self, at: 0)
            URLSession.store(config: self)
        }
    }
}

@objc extension URLSession {
    // The swizzled class func to create (NS)URLSession with the given configuration
    // We monitor all sessions implicitly
    class func instana_session(configuration: URLSessionConfiguration) -> URLSession {
        configuration.registerInstanaURLProtocol()
        return URLSession.instana_session(configuration: configuration)
    }

    private static let lock = NSLock()
    private static var _unsafe_allSessionConfigs = [URLSessionConfiguration]()
    static var allSessionConfigs: [URLSessionConfiguration] {
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

    static func store(config: URLSessionConfiguration) {
        if !allSessionConfigs.contains(config) {
            allSessionConfigs.append(config)
        }
    }

    static func removeInstanaURLProtocol() {
        allSessionConfigs.forEach { $0.protocolClasses?.removeAll(where: { (protocolClass) -> Bool in
            protocolClass == InstanaURLProtocol.self
        }) }
    }
}

extension InstanaURLProtocol {
    // We do some swizzling to inject our InstanaURLProtocol to all custom sessions automatically
    static func install() {
        URLSession.allSessionConfigs.removeAll()
        prepareWebView
        prepareURLSessions
    }

    static func deinstall() {
        URLSession.removeInstanaURLProtocol()
    }

    static let prepareWebView: () = {
        guard let something = WKWebView().value(forKey: "browsingContextController") as? NSObject else { return }
        let selector = NSSelectorFromString("registerSchemeForCustomProtocol:")
        if type(of: something).responds(to: selector) {
            type(of: something).perform(selector, with: "http")
            type(of: something).perform(selector, with: "https")
        }
    }()

    static let prepareURLSessions: () = {
        let originalSelector = #selector(URLSession.init(configuration:))
        let newSelector = #selector(URLSession.instana_session(configuration:))
        guard let originalMethod = class_getClassMethod(URLSession.self, originalSelector),
            let newMethod = class_getClassMethod(URLSession.self, newSelector) else { return }

        // Should be prefered over the function (method)
//        let newBlock: @convention(block) (AnyObject, Selector, URLSessionConfiguration) -> (URLSession) = {_,_,configuration in
//            configuration.registerInstanaURLProtocol()
//            return URLSession.instana_session(configuration: configuration)
//        }
//        let newImp = imp_implementationWithBlock(newBlock)

        let className = object_getClassName(URLSession.self)
        let didAddMethod = class_addMethod(objc_getMetaClass(className) as? AnyClass,
                                           originalSelector, method_getImplementation(newMethod),
                                           method_getTypeEncoding(newMethod))
        if didAddMethod {
            class_replaceMethod(URLSession.self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, newMethod)
        }
    }()
}

private extension URLSessionTask {
    func internalSession() -> URLSession? {
        let selector = NSSelectorFromString("session")
        guard responds(to: selector) else { return nil }
        guard let implementation = type(of: self).instanceMethod(for: selector) else { return nil }
        typealias FunctionSignature = @convention(c) (AnyObject, Selector) -> URLSession?
        let sessionMethod = unsafeBitCast(implementation, to: FunctionSignature.self)
        return sessionMethod(self, selector)
    }
}
