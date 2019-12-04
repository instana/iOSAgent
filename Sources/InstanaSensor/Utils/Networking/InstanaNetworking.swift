//  Created by Nikola Lajic on 3/7/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

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
        send(request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let httpResponse = response as? HTTPURLResponse {
                completion(.success(statusCode: httpResponse.statusCode))
            }
            else {
                completion(.failure(InstanaError(code: .invalidResponse, description: "Unexpected response type")))
            }
        }.resume()
    }
}
