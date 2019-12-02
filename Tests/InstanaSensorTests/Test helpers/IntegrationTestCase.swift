import Foundation
import XCTest
@testable import InstanaSensor

enum IntegrationTestCaseError: Error {
    case empty
    case unknonw
}

@available(iOS 12.0, *)
class IntegrationTestCase: XCTestCase {

    struct Defaults {
        static let baseURL = URL(string: "http://localhost:8080")!
    }

    var expectation: XCTestExpectation!
    var session: URLSession!
    var task: URLSessionTask!
    var mockserver: EchoWebServer!

    override func setUp() {
        super.setUp()

        mockserver = EchoWebServer()
        mockserver.start()
        expectation = expectation(description: UUID().uuidString)
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
    }

    func load(url: URL = Defaults.baseURL, completion: @escaping (Result<Data, Error>) -> Void) {
        task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else if let data = data {
                completion(Result.success(data))
            } else {
                completion(Result.failure(IntegrationTestCaseError.empty))
            }
            self.fulfilled()
        }
        task.resume()
        wait(for: [expectation], timeout: 10.0)
    }

    func fulfilled() {
        expectation.fulfill()
    }
}
