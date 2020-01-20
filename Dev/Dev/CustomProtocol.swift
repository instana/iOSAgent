import Foundation
import WebKit
import InstanaAgent

class CustomProtocol: URLProtocol {

    private lazy var session: URLSession = { URLSession(configuration: .default, delegate: self, delegateQueue: nil) }()

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url, let scheme = url.scheme else { return false }
        return ["http", "https"].contains(scheme)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let task = session.dataTask(with: request)
        task.resume()
    }

    override func stopLoading() {
        session.invalidateAndCancel()
    }
}

extension CustomProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

extension CustomProtocol: URLSessionDataDelegate {
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
}
