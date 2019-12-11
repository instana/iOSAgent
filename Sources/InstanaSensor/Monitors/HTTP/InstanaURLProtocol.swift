//  Created by Nikola Lajic on 12/25/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

@objc extension URLSession {
    // The swizzled class func to create (NS)URLSession with the given configuration
    // We monitor all sessions implicitly
    @objc class func instana_session(configuration: URLSessionConfiguration) -> URLSession {
        Instana.current?.monitors.http?.install(configuration)
        return URLSession.instana_session(configuration: configuration)
    }
}

class InstanaURLProtocol: URLProtocol {
    // We do some swizzling to inject our InstanaURLProtocol to all custom sessions automatically
    static let prepare: () = {
        let originalSelector = #selector(URLSession.init(configuration:))
        let newSelector = #selector(URLSession.instana_session(configuration:))

        guard let originalMethod = class_getClassMethod(URLSession.self, originalSelector),
            let newMethod = class_getClassMethod(URLSession.self, newSelector) else { return }

        method_exchangeImplementations(originalMethod, newMethod)
        // TODO: This should be actually the right behavior
//        return
//        let didAddMethod = class_addMethod(URLSession.self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))
//        if didAddMethod {
//            class_replaceMethod(URLSession.self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//        } else {
//            method_exchangeImplementations(originalMethod, newMethod)
//        }
    }()

    enum Mode {
        case enabled, disabled
    }

    static var mode: Mode = .disabled

    private lazy var session: URLSession = {
        URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }()
    private(set) lazy var sessionConfiguration: URLSessionConfiguration = { .default }()
    private var marker: HTTPMarker?
    
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
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            marker?.finished(error: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
            marker?.finished(responseCode: response?.statusCode ?? 0)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        marker?.set(responseSize: Instana.Types.HTTPSize.response(task: task, transactionMetrics: metrics.transactionMetrics))
    }
}

extension InstanaURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
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
