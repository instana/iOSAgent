import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTests: InstanaTestCase {

    func test_setup() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        Instana.setup(key: key, reportingURL: reportingURL)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .automatic)
        AssertEqualAndNotNil(Instana.current?.session.configuration, .default(key: key, reportingURL: reportingURL))
    }

    func test_setup_manual_http_capture() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let httpCaptureConfig: HTTPCaptureConfig = .manual

        // When
        Instana.setup(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .manual)
        AssertEqualAndNotNil(Instana.current?.session.configuration, .default(key: key, reportingURL: reportingURL, httpCaptureConfig: httpCaptureConfig))
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
        Instana.current = Instana(configuration: .default(key: "KEY", reportingURL: .random), monitors: Monitors(.mock, reporter: reporter))
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(excpectedBeacon?.state, SessionProfileBeacon.State.start)
    }

    func test_captureHTTP_request() {
        // Given
        let config = InstanaConfiguration.default(key: "KEY", reportingURL: .random, httpCaptureConfig: .manual)
        let env = InstanaSession.mock(configuration: config)
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
        let sut = Instana.startCapture(request, viewName: "DetailView")
        sut.finish(response: HTTPURLResponse(url: .random, statusCode: 200, httpVersion: nil, headerFields: nil)!, error: nil)
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(sut.url, request.url)
        AssertEqualAndNotNil(sut.trigger, .manual)
        AssertEqualAndNotNil(excpectedBeacon?.url, request.url)
        AssertEqualAndNotNil(excpectedBeacon?.method, "PUT")
        AssertEqualAndNotNil(excpectedBeacon?.responseCode, 200)
        AssertEqualAndNotNil(excpectedBeacon?.viewName, "DetailView")
    }

    func test_captureHTTP_request_missing_method_should_fall_to_default_GET() {
        // Given
        var request = URLRequest(url: URL(string: "https://www.example.com")!)
        request.httpMethod = nil

        // When
        let sut = Instana.startCapture(request)

        // Then
        AssertEqualAndNotNil(sut.method, "GET")
    }

    func test_setUser() {
        // Given
        let id = UUID().uuidString
        let email = "email@example.com"
        let name = "John Appleseed"

        // When
        Instana.setUser(id: id, email: email, name: name)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.id, id)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.email, email)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.name, name)
    }

    func test_setViewName() {
        // Given
        let viewName = "Some View"
        let env = InstanaSession.mock(configuration: config)
        var didReport = false
        let reporter = MockReporter {beacon in
            didReport = (beacon is ViewChange) && beacon.viewName == viewName
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))
        Instana.current?.session.propertyHandler.properties.view = "Old View"

        // When
        Instana.setView(name: viewName)

        // Then
        AssertTrue(didReport)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.view, viewName)
    }

    func test_setViewName_shouldnotreport_if_view_not_changed() {
        // Given
        let viewName = "Some View"
        let env = InstanaSession.mock(configuration: config)
        var didReport = false
        let reporter = MockReporter {beacon in
            didReport = (beacon is ViewChange) && beacon.viewName == viewName
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))
        Instana.current?.session.propertyHandler.properties.view = viewName

        // When
        Instana.setView(name: viewName)

        // Then
        AssertTrue(didReport == false)
    }

    func test_setMetaData() {
        // Given
        let given = ["Key": "Value", "Key2": "Value2"]

        // When
        Instana.setMeta(value: given["Key"]!, key: "Key")
        Instana.setMeta(value: given["Key2"]!, key: "Key2")

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.metaData, given)
    }

    func test_setMetaData_to_long_value() {
        // Given
        let valid = "\((0...255).map {_ in "A"}.joined())"
        let invalid = "\((0...256).map {_ in "A"}.joined())"

        // When
        Instana.setMeta(value: valid, key: "valid")
        Instana.setMeta(value: invalid, key: "invalid")

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.metaData?["valid"], valid)
        AssertTrue(Instana.current?.session.propertyHandler.properties.metaData?.count == 1)
    }

    func test_setMetaData_ignore_too_many_fields() {
        // When
        (0...50).forEach { index in
            Instana.setMeta(value: "V-\(index)", key: "\(index)")
        }

        // Then

        let values = Array(Instana.current!.session.propertyHandler.properties.metaData!.values)
        let keys = Array(Instana.current!.session.propertyHandler.properties.metaData!.keys)
        AssertTrue(values.contains("V-0") == true)
        AssertTrue(values.contains("V-49") == true)
        AssertTrue(values.contains("V-50") == false)
        AssertTrue(keys.contains("49") == true)
        AssertTrue(keys.contains("50") == false)
        AssertTrue(Instana.current!.session.propertyHandler.properties.metaData?.count == 50)
    }

    func test_setIgnoreURLs() {
        // Given
        let urlToIgnore = URL.random
        let secondURLToIgnore = URL.random

        // When
        Instana.setIgnore(urls: [urlToIgnore])

        // Then
        AssertTrue(IgnoreURLHandler.exactURLs.contains(urlToIgnore))
        AssertEqualAndNotZero(IgnoreURLHandler.exactURLs.count, 1)

        // When
        Instana.setIgnore(urls: [secondURLToIgnore])

        // Then
        AssertTrue(IgnoreURLHandler.exactURLs.contains(urlToIgnore))
        AssertTrue(IgnoreURLHandler.exactURLs.contains(secondURLToIgnore))
        AssertEqualAndNotZero(IgnoreURLHandler.exactURLs.count, 2)
    }

    func test_setIgnoreMatchingRegex() {
        // Given
        let regex = try! NSRegularExpression(pattern: ".*(&|\\?)password=.*")
        let anotherRegex = try! NSRegularExpression(pattern: ".*http:.*")

        // When
        Instana.setIgnoreURLs(matching: [regex])

        // Then
        AssertTrue(IgnoreURLHandler.regex.contains(regex))
        AssertEqualAndNotZero(IgnoreURLHandler.regex.count, 1)

        // When
        Instana.setIgnoreURLs(matching: [anotherRegex])

        // Then
        AssertTrue(IgnoreURLHandler.regex.contains(regex))
        AssertTrue(IgnoreURLHandler.regex.contains(anotherRegex))
        AssertEqualAndNotZero(IgnoreURLHandler.regex.count, 2)
    }

    func test_ignoreURLSession() {
        // Given
        let session = URLSession(configuration: .default)
        let anotherSession = URLSession(configuration: .default)

        // When
        Instana.ignore(session)

        // Then
        AssertTrue(IgnoreURLHandler.urlSessions.contains(session))
        AssertEqualAndNotZero(IgnoreURLHandler.urlSessions.count, 1)

        // When
        Instana.ignore(anotherSession)

        // Then
        AssertTrue(IgnoreURLHandler.urlSessions.contains(session))
        AssertTrue(IgnoreURLHandler.urlSessions.contains(anotherSession))
        AssertEqualAndNotZero(IgnoreURLHandler.urlSessions.count, 2)
    }

    func test_reportCustom_simple() {
        // Given
        let name = "Custom Event"
        let env = InstanaSession.mock(configuration: config)
        var didReport = false
        let reporter = MockReporter {beacon in
            didReport = (beacon as? CustomBeacon)?.name == name
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))

        // When
        Instana.reportCustom(name: name)

        // Then
        AssertTrue(didReport)
    }

    func test_reportCustom_AllValues() {
        // Given
        let name = "Custom Event"
        let duration: Int64 = 123
        let backendID = "B123"
        let error = NSError(domain: "Domain", code: 100, userInfo: nil)
        let meta = ["Key": "Value"]
        let viewName = "Some View"
        let env = InstanaSession.mock(configuration: config)
        var didReport: CustomBeacon? = nil
        let reporter = MockReporter {beacon in
            didReport = beacon as? CustomBeacon
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))

        // When
        Instana.reportCustom(name: name, duration: duration, backendTracingID: backendID, error: error, meta: meta, viewName: viewName)

        // Then
        AssertTrue(didReport != nil)
        AssertEqualAndNotNil(didReport?.name, name)
        AssertEqualAndNotNil(didReport?.duration, duration)
        AssertEqualAndNotNil(didReport?.backendTracingID, backendID)
        AssertEqualAndNotNil((didReport?.error as NSError?), error)
        AssertEqualAndNotNil(didReport?.meta, meta)
        AssertEqualAndNotNil(didReport?.viewName, viewName)
    }

    func test_reportCustom_implicit_values() {
        // Given
        let name = "Custom Event"
        let env = InstanaSession.mock(configuration: config)
        var didReport: CustomBeacon? = nil
        let reporter = MockReporter {beacon in
            didReport = beacon as? CustomBeacon
        }
        Instana.current = Instana(configuration: config, monitors: Monitors(env, reporter: reporter))

        // When
        Instana.reportCustom(name: name)

        // Then
        AssertTrue(didReport != nil)
        AssertEqualAndNotNil(didReport?.name, name)
        AssertEqualAndNotNil(didReport?.duration, 0)
        AssertTrue(didReport?.backendTracingID == nil)
        AssertTrue(didReport?.meta == nil)
        AssertTrue(didReport?.error == nil)
        AssertEqualAndNotNil(didReport?.viewName, Instana.current?.session.propertyHandler.properties.view)
    }
}
