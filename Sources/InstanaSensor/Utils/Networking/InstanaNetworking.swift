//  Created by Nikola Lajic on 3/7/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaNetworking {
    enum Result {
        case success(statusCode: Int)
        case failure(error: Error)
    }
    
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    typealias LoadResult = (Result) -> Void
    typealias Loader = (URLRequest, @escaping DataTaskResult) -> URLSessionDataTask
    
    private let load: Loader
    private let restrictedLoad: Loader
    
    init(load: @escaping Loader = URLSession(configuration: .default).dataTask(with:completionHandler:),
         restrictedLoad: @escaping Loader = URLSession(configuration: .wifi).dataTask(with:completionHandler:)) {
        self.load = load
        self.restrictedLoad = restrictedLoad
    }
    
    func load(request: URLRequest, restricted: Bool = false, completion: @escaping LoadResult) {
        let loadRequest = restricted ? restrictedLoad : load
        loadRequest(request) { data, response, error in
            if let error = error {
                completion(.failure(error: error))
            }
            else if let httpResponse = response as? HTTPURLResponse {
                completion(.success(statusCode: httpResponse.statusCode))
            }
            else {
                completion(.failure(error: InstanaError(code: .invalidResponse, description: "Unexpected response type")))
            }
        }.resume()
    }
}

extension URLSessionConfiguration {
    class var wifi: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = false
        return configuration
    }
}
