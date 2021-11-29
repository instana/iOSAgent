//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

@available(iOS 12.0, *)
class URLSessionTaskIntegrationTests: InstanaTestCase {

    var testURL: URL!
    var reporter: Reporter!
    var webserver: Webserver!

    override func setUp() {
        super.setUp()
        webserver = Webserver(port: 9998)
        webserver.start()
        testURL = URL(string: "http://127.0.0.1:9998")!
    }

    override func tearDown() {
        Instana.current = nil
        reporter = nil
    }

    func test_dataTask() {
        // Given
        let waitFor = expectation(description: "test_dataTask")
        var receivedData: Data?
        var sentBeacon: CoreBeacon?
        createInstana { beacon in
            if beacon?.hu == self.testURL.absoluteString {
                sentBeacon = beacon
                waitFor.fulfill()
            }
        }

        // When
        URLSession.shared.dataTask(with: testURL) {data, response, error in
            DispatchQueue.main.async {
                receivedData = data
            }
        }.resume()
        wait(for: [waitFor], timeout: 10)

        // Then
        XCTAssertNotNil(receivedData)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hs, "200")
        AssertEqualAndNotNil(sentBeacon?.hu, testURL.absoluteString)
    }

    func test_downloadTask() {
        // Given
        let waitFor = expectation(description: "test_downloadTask")
        var receivedData = Data()
        var sentBeacon: CoreBeacon?
        createInstana { beacon in
            if beacon?.hu == self.testURL.absoluteString {
                sentBeacon = beacon
                waitFor.fulfill()
            }
        }

        // When
        URLSession.shared.downloadTask(with: testURL) {localURL, response, error in
            DispatchQueue.main.async {
                receivedData = (try? Data(contentsOf: localURL!)) ?? Data()
            }
        }.resume()
        wait(for: [waitFor], timeout: 10)

        // Then
        AssertTrue(receivedData.count > 0)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hs, "200")
        AssertEqualAndNotNil(sentBeacon?.hu, testURL.absoluteString)
    }

    func test_uploadTask() {
        // Given
        let waitFor = expectation(description: "test_uploadTask")
        let boundary = UUID().uuidString
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"img.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/octet-stream\r\n".data(using: .utf8)!)
        data.append("Uploaded".data(using: .utf8)!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: testURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        var sentBeacon: CoreBeacon?
        createInstana { beacon in
            if beacon?.hu == self.testURL.absoluteString {
                sentBeacon = beacon
                waitFor.fulfill()
            }
        }

        // When
        URLSession(configuration: .default).uploadTask(with: request, from: data) {_, _, _ in
        }.resume()
        wait(for: [waitFor], timeout: 60)

        // Then verify the sent beacon body in the URLRequest going out to the server
        AssertEqualAndNotNil(sentBeacon?.hm, "POST")
        AssertEqualAndNotNil(sentBeacon?.hs, "200")
        AssertEqualAndNotNil(sentBeacon?.hu, testURL.absoluteString)
    }

    func createInstana(done: @escaping (CoreBeacon?) -> Void) {
        reporter = Reporter(session, send: { request, completion in
            completion(.success(statusCode: 200))
            let value = String(data: request.httpBody ?? Data(), encoding: .utf8)
            let sentBeacon = try? CoreBeacon.create(from: value ?? "")
            done(sentBeacon)
        })
        reporter.queue.items.removeAll()
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))
    }
}
