//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

@available(iOS 12.0, *)
class URLSessionTaskIntegrationTests: InstanaTestCase {

    var testURL: URL!
    var webserver: Webserver!
    var reporter: Reporter!
    var sentRequest: URLRequest!
    var sentBeacon: CoreBeacon?

    override func setUp() {
        super.setUp()
        webserver = Webserver(port: 9998)
        webserver.start()
        testURL = URL(string: "http://127.0.0.1:9998")!

        reporter = Reporter(session, send:  { request, completion in
            self.sentRequest = request
            completion(.success(statusCode: 200))
            let value = String(data: request.httpBody ?? Data(), encoding: .utf8)
            self.sentBeacon = try? CoreBeacon.create(from: value ?? "")
        })
        reporter.queue.items.removeAll()
        Instana.current = Instana(session: session, configuration: session.configuration, monitors: Monitors(session, reporter: reporter))

        let waitForLaunch = expectation(description: "webserver")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            waitForLaunch.fulfill()
        }
        wait(for: [waitForLaunch], timeout: 5)
    }

    override func tearDown() {
        webserver.stop()
        webserver = nil
        sentBeacon = nil
        Instana.current = nil
    }

    func test_dataTask() {
        // Given
        let waitFor = expectation(description: "test_dataTask")
        var receivedData: Data?

        // When
        URLSession.shared.dataTask(with: testURL) {data, response, error in
            self.run(after: 2.0) {
                if self.sentBeacon?.hu == self.testURL.absoluteString {
                    receivedData = data
                    waitFor.fulfill()
                }
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
        var downloadedData = Data()

        // When
        URLSession.shared.downloadTask(with: testURL) {localURL, response, error in
            self.run(after: 2.0) {
                downloadedData = (try? Data(contentsOf: localURL!)) ?? Data()
                if self.sentBeacon?.hu == self.testURL.absoluteString {
                    waitFor.fulfill()
                }
            }
        }.resume()
        wait(for: [waitFor], timeout: 10)

        // Then
        AssertTrue(downloadedData.count > 0)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hs, "200")
        AssertEqualAndNotNil(sentBeacon?.hu, testURL.absoluteString)
    }

    func test_uploadTask() {
        // Given
        let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        view.backgroundColor = .red
        let waitFor = expectation(description: "test_uploadTask")
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        let imgData = image.jpegData(compressionQuality: 0.9)!
        let boundary = UUID().uuidString
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"img.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpg\r\n\r\n".data(using: .utf8)!)
        data.append(imgData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: testURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

        // When
        URLSession.shared.uploadTask(with: request, from: data) {data, response, error in
            self.run(after: 2.0) {
                if self.sentBeacon?.hu == self.testURL.absoluteString {
                    waitFor.fulfill()
                }
            }
        }.resume()
        wait(for: [waitFor], timeout: 10)

        // Then verify the sent beacon body in the URLRequest going out to the server
        AssertEqualAndNotNil(sentBeacon?.hm, "POST")
        AssertEqualAndNotNil(sentBeacon?.hs, "200")
        AssertEqualAndNotNil(sentBeacon?.hu, testURL.absoluteString)
    }
}
