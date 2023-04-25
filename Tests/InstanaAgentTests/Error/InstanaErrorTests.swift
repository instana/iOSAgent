//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaErrorTests: InstanaTestCase {

    func test_localizedDescription() {
        var error = InstanaError.fileHandling("mock file handling")
        XCTAssertEqual(error.localizedDescription, "File handling failed mock file handling")

        error = InstanaError.invalidRequest
        XCTAssertEqual(error.localizedDescription, "Invalid URLRequest")

        error = InstanaError.httpClientError(202)
        XCTAssertEqual(error.localizedDescription, "HTTP Client error occured code: 202")

        error = InstanaError.httpServerError(303)
        XCTAssertEqual(error.localizedDescription, "HTTP Server  error occured code: 303")

        error = InstanaError.invalidResponse
        XCTAssertEqual(error.localizedDescription, "Invalid response type")

        error = InstanaError.missingAppKey
        XCTAssertEqual(error.localizedDescription, "Missing Instana app key")

        error = InstanaError.unknownType("mock String")
        XCTAssertEqual(error.localizedDescription, "Type mismatch mock String")

        error = InstanaError.noWifiAvailable
        XCTAssertEqual(error.localizedDescription, "No WIFI Available")

        error = InstanaError.offline
        XCTAssertEqual(error.localizedDescription, "No Internet connection available")

        error = InstanaError.lowBattery
        XCTAssertEqual(error.localizedDescription, "Battery too low for flushing")

        let mockError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        error = InstanaError.underlying(mockError)
        XCTAssertEqual(error.localizedDescription, "Underlying error \(mockError)")

        let errors = [mockError]
        error = InstanaError.multiple(errors)
        XCTAssertEqual(error.localizedDescription, "Underlying errors \(errors)")
    }

    func test_errorDescription() {
        let error = InstanaError.invalidRequest
        XCTAssertEqual(error.errorDescription, error.localizedDescription)
    }

    func test_isHTTPClientError() {
        // Given
        var error: InstanaError

        // Positive
        error = InstanaError.httpClientError(505)
        var ret = error.isHTTPClientError
        XCTAssertTrue(ret)

        // Negative
        error = InstanaError.invalidRequest
        ret = error.isHTTPClientError
        XCTAssertFalse(ret)
    }

    func test_isUnknownType() {
        // Given
        var error: InstanaError

        // Positive
        error = InstanaError.unknownType("mock type")
        var ret = error.isUnknownType
        XCTAssertTrue(ret)

        // Negative
        error = InstanaError.invalidRequest
        ret = error.isUnknownType
        XCTAssertFalse(ret)
    }

    func test_create() {
        // Given
        var nsError: NSError

        // Positive
        nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        var instError = InstanaError.create(from: nsError)
        XCTAssertEqual(instError, InstanaError.offline)

        // Negative
        nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        instError = InstanaError.create(from: nsError)
        XCTAssertNotEqual(instError, InstanaError.offline)
        AssertEqualAndNotNil(instError, .underlying(instError))
    }

    func test_optional_isHTTPClientError() {
        // Given
        var error: InstanaError?

        // Positive
        error = .httpClientError(505)
        var ret = error.isHTTPClientError
        XCTAssertTrue(ret)

        // Negative
        error = nil
        ret = error.isHTTPClientError
        XCTAssertFalse(ret)
    }

    func test_optional_isUnknownType() {
        // Given
        var error: InstanaError?

        // Positive
        error = .unknownType("mock type")
        var ret = error.isUnknownType
        XCTAssertTrue(ret)

        // Negative
        error = nil
        ret = error.isUnknownType
        XCTAssertFalse(ret)
    }
}
