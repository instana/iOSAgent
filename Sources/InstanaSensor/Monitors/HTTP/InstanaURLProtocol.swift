//  Created by Nikola Lajic on 12/25/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

internal class InstanaURLProtocol: URLProtocol {
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
        guard let url = request.url, let scheme = url.scheme else { return false }
        return ["http", "https"].contains(scheme)
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        marker = try? Instana.current.monitors.http?.mark(request)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    override func stopLoading() {
        session.invalidateAndCancel()
        if let marker = marker, case .started = marker.state { marker.canceled() }
    }
}

extension InstanaURLProtocol: URLSessionTaskDelegate {
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            marker?.ended(error: error, responseSize: task.countOfBytesReceived)
        }
        else {
            client?.urlProtocolDidFinishLoading(self)
            marker?.ended(responseCode: (task.response as? HTTPURLResponse)?.statusCode ?? 0, responseSize: task.countOfBytesReceived)
        }
    }
}

extension InstanaURLProtocol: URLSessionDataDelegate {
    internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
    }
    
    internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
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
