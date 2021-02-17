//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

class InstanaNetworking {
    enum Result {
        case success(statusCode: Int)
        case failure(Error)
    }

    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    typealias LoadResult = (Result) -> Void
    typealias NetworkLoader = (URLRequest, @escaping DataTaskResult) -> URLSessionDataTask
    private let send: NetworkLoader

    init(send: @escaping NetworkLoader = URLSession(configuration: .default).dataTask(with:completionHandler:)) {
        self.send = send
    }

    func send(request: URLRequest, completion: @escaping LoadResult) {
        send(request) { _, response, error in
            if let error = error {
                return completion(.failure(InstanaError.create(from: error)))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(InstanaError.invalidResponse))
            }
            switch httpResponse.statusCode {
            case 200 ... 399:
                completion(.success(statusCode: httpResponse.statusCode))
            case 400 ... 499:
                completion(.failure(InstanaError.httpClientError(httpResponse.statusCode)))
            case 500 ... 599:
                completion(.failure(InstanaError.httpServerError(httpResponse.statusCode)))
            default:
                completion(.failure(InstanaError.invalidResponse))
            }
        }.resume()
    }
}
