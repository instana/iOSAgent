//
//  File.swift
//  
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation
import XCTest
@testable import InstanaSensor

enum ASyncTestCaseError: Error {
    case empty
    case unknonw
}

@available(iOS 12.0, *)
class ASyncTestCase: XCTestCase {

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

    func load(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else if let data = data {
                completion(Result.success(data))
            } else {
                completion(Result.failure(ASyncTestCaseError.empty))
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

@available(iOS 12.0, *)
class BeaconSubmissionTest: ASyncTestCase {

    func test_Network() {
        let url = URL(string: "http://localhost:8080")!
        load(url: url) {result in
            XCTAssertNotNil(try? result.map {$0}.get())
        }
    }
}
