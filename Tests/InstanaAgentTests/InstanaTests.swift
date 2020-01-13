import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTests: InstanaTestCase {

    func test_setup() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let httpCaptureConfig: HTTPCaptureConfig = .manual

        // When
        Instana.setup(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.environment.configuration, .default(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig))
    }

    func test_setup_and_expect_SessionProfileBeacon() {
        // Given
        let waitRequest = expectation(description: "test_setup_and_expect_SessionProfileBeacon")
        var excpectedBeacon: SessionProfileBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? SessionProfileBeacon {
                excpectedBeacon = beacon
                waitRequest.fulfill()
            }
        }

        // When
        Instana.current = Instana(configuration: .default(key: "KEY"), monitors: Monitors(.mock, reporter: reporter))
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(excpectedBeacon?.state, SessionProfileBeacon.State.start)
    }

    func test_captureHTTP_request() {
        // Given
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: .random, httpCaptureConfig: .manual)
        let env = InstanaEnvironment.mock(configuration: config)
        let waitRequest = expectation(description: "test_captureHTTP_request")
        var excpectedBeacon: HTTPBeacon?
        var request = URLRequest(url: URL(string: "https://www.instana.com")!)
        request.httpMethod = "PUT"
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                excpectedBeacon = beacon
                waitRequest.fulfill()
            }
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))

        // When
        let sut = try? Instana.startCapture(request, viewName: "DetailView")
        sut?.finish(responseCode: 200)
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(sut?.url, request.url)
        AssertEqualAndNotNil(sut?.trigger, .manual)
        AssertEqualAndNotNil(excpectedBeacon?.url, request.url)
        AssertEqualAndNotNil(excpectedBeacon?.method, "PUT")
        AssertEqualAndNotNil(excpectedBeacon?.responseCode, 200)
        AssertEqualAndNotNil(excpectedBeacon?.viewName, "DetailView")
    }

    func test_captureHTTP_request_missing_instance() {
        // Given
        let waitRequest = expectation(description: "test_captureHTTP_request_missing_instance")
        let request = URLRequest(url: URL(string: "https://www.example.com")!)
        var expectedError: Error?
        Instana.current = nil

        // When
        XCTAssertThrowsError(try Instana.startCapture(request)) {error in
            // Then
            expectedError = error
            waitRequest.fulfill()
        }
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil((expectedError as? InstanaError)?.code, InstanaError.Code.instanaInstanceNotFound.rawValue)
    }

    func test_captureHTTP_request_missing_method_should_fall_to_default_GET() {
        // Given
        var request = URLRequest(url: URL(string: "https://www.example.com")!)
        request.httpMethod = nil
        let reporter = MockReporter {_ in }
        Instana.current = Instana(configuration: .default(key: "KEY"), monitors: Monitors(.mock, reporter: reporter))

        // When
        let sut = try? Instana.startCapture(request)

        // Then
        AssertEqualAndNotNil(sut?.method, "GET")
    }

    func test_setUser() {
        // Given
        let id = UUID().uuidString
        let email = "email@example.com"
        let name = "John Appleseed"

        // When
        Instana.setUser(id: id, email: email, name: name)

        // Then
        AssertEqualAndNotNil(Instana.propertyHandler.properties.user?.id, id)
        AssertEqualAndNotNil(Instana.propertyHandler.properties.user?.email, email)
        AssertEqualAndNotNil(Instana.propertyHandler.properties.user?.name, name)
    }

    func test_setViewName() {
        // Given
        let viewName = "Some View"

        // When
        Instana.setView(name: viewName)

        // Then
        AssertEqualAndNotNil(Instana.propertyHandler.properties.view, viewName)
    }

    func test_setMetaData() {
        // Given
        let given = ["Key": "Value", "Key2": "Value2"]

        // When
        Instana.setMeta(value: given["Key"]!, key: "Key")
        Instana.setMeta(value: given["Key2"]!, key: "Key2")

        // Then
        AssertEqualAndNotNil(Instana.propertyHandler.properties.metaData, given)
    }

    func test_setMetaData_to_long_value() {
        // Given
        let valid = "\((0...255).map {_ in "A"}.joined())"
        let invalid = "\((0...256).map {_ in "A"}.joined())"

        // When
        Instana.setMeta(value: valid, key: "valid")
        Instana.setMeta(value: invalid, key: "invalid")

        // Then
        AssertEqualAndNotNil(Instana.propertyHandler.properties.metaData?["valid"], valid)
        AssertTrue(Instana.propertyHandler.properties.metaData?.count == 1)
    }

    func test_setMetaData_ignore_too_many_fields() {
        // When
        (0...50).forEach { index in
            Instana.setMeta(value: "V-\(index)", key: "\(index)")
        }

        // Then

        let values = Array(Instana.propertyHandler.properties.metaData!.values)
        let keys = Array(Instana.propertyHandler.properties.metaData!.keys)
        AssertTrue(values.contains("V-0") == true)
        AssertTrue(values.contains("V-49") == true)
        AssertTrue(values.contains("V-50") == false)
        AssertTrue(keys.contains("49") == true)
        AssertTrue(keys.contains("50") == false)
        AssertTrue(Instana.propertyHandler.properties.metaData?.count == 50)
    }
}
