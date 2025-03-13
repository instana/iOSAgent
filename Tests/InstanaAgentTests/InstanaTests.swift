//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaTests: InstanaTestCase {

    func test_setup_with_options_default_success() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        let ret = Instana.setup(key: key, reportingURL: reportingURL, options: nil)

        // Then
        AssertTrue(ret)
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertTrue(Instana.collectionEnabled)
        AssertTrue(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)

        let config = Instana.current?.session.configuration
        XCTAssertNotNil(config)
        AssertEqualAndNotNil(config!.key, key)
        AssertEqualAndNotNil(config!.reportingURL, reportingURL)
        AssertEqualAndNotNil(config!.httpCaptureConfig, .automatic)
        AssertEqualAndNotNil(config!.slowSendInterval, 0.0)
        AssertEqualAndNotNil(config!.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
        AssertFalse(config!.monitorTypes.contains(.crash))

        let session = Instana.current?.session
        XCTAssertNotNil(session)
        AssertTrue(session!.collectionEnabled)
    }

    func test_setup_with_options_custom_success() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        let options = InstanaSetupOptions(httpCaptureConfig: .automaticAndManual,
                                          collectionEnabled: false)
        options.enableCrashReporting = true
        options.suspendReportingOnLowBattery = true
        options.suspendReportingOnCellular = true
        options.slowSendInterval = 20.0
        options.autoCaptureScreenNames = false
        let ret = Instana.setup(key: key, reportingURL: reportingURL, options: options)

        // Then
        AssertTrue(ret)
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertFalse(Instana.collectionEnabled)
        AssertFalse(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)

        let config = Instana.current?.session.configuration
        XCTAssertNotNil(config)
        AssertEqualAndNotNil(config!.key, key)
        AssertEqualAndNotNil(config!.reportingURL, reportingURL)
        AssertEqualAndNotNil(config!.httpCaptureConfig, .automaticAndManual)
        AssertEqualAndNotNil(config!.slowSendInterval, options.slowSendInterval)
        AssertEqualAndNotNil(config!.usiRefreshTimeIntervalInHrs, options.usiRefreshTimeIntervalInHrs)
        AssertTrue(config!.monitorTypes.contains(.crash))

        AssertEqualAndNotNil(Instana.current?.session.collectionEnabled, options.collectionEnabled)
        AssertFalse(options.collectionEnabled)
    }

    func test_setup_with_options_failure() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        let options = InstanaSetupOptions(slowSendInterval: -1.0)
        let ret1 = Instana.setup(key: key, reportingURL: reportingURL, options: options)

        // Then
        AssertFalse(ret1)

        // case 2
        let ret2 = Instana.setup(key: key, reportingURL: reportingURL, options: InstanaSetupOptions(slowSendInterval: 7777))
        // Then
        AssertFalse(ret2)
    }

    func test_setup_invalid_configuration_empty_key() {
        // Given
        let reportingURL = URL(string: "http://www.instana.com")!
        _ = Instana.setup(key: "", reportingURL: reportingURL, options: nil)

        // Then
        AssertFalse(Instana.current!.session.configuration.isValid)
    }

    func test_setup() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        _ = Instana.setup(key: key, reportingURL: reportingURL, options: nil)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertTrue(Instana.collectionEnabled)
        AssertTrue(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.key, key)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .automatic)
        AssertFalse(Instana.current!.session.configuration.monitorTypes.contains(.crash))
        AssertEqualAndNotNil(Instana.current?.session.configuration.slowSendInterval, 0.0)
        AssertEqualAndNotNil(Instana.current?.session.configuration.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
    }

    func test_setupInternal() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        let hybridOptions = HybridAgentOptions(id: "f", version:"3.0.6")
        _ = Instana.setupInternal(key: key, reportingURL: reportingURL, options: nil, hybridOptions: hybridOptions)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertTrue(Instana.collectionEnabled)
        AssertTrue(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .automatic)
        XCTAssertNotEqual(Instana.current?.session.configuration,
                             .default(key: key, reportingURL: reportingURL, enableCrashReporting: false))
        AssertEqualAndNotNil(Instana.current?.session.configuration.slowSendInterval, 0.0)
        AssertEqualAndNotNil(Instana.current?.session.configuration.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
    }

    func test_setup_disabled() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let httpCaptureConfig: HTTPCaptureConfig = .manual

        // When
        let options = InstanaSetupOptions(httpCaptureConfig: httpCaptureConfig, collectionEnabled: false)
        _ = Instana.setup(key: key, reportingURL: reportingURL, options: options)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertFalse(Instana.collectionEnabled)
        AssertFalse(Instana.current!.session.collectionEnabled)
    }

    func test_setup_manual_http_capture() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let httpCaptureConfig: HTTPCaptureConfig = .manual

        // When
        let options = InstanaSetupOptions(httpCaptureConfig: httpCaptureConfig)
        _ = Instana.setup(key: key, reportingURL: reportingURL, options: options)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .manual)
    }

    func test_setup_automaticAndManual_http_capture() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let httpCaptureConfig: HTTPCaptureConfig = .automaticAndManual

        // When
        let options = InstanaSetupOptions(httpCaptureConfig: httpCaptureConfig)
        _ = Instana.setup(key: key, reportingURL: reportingURL, options: options)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.session.configuration.httpCaptureConfig, .automaticAndManual)
    }

    func test_setup_and_expect_SessionProfileBeacon() {
        // Given
        let session: InstanaSession = .mock(configuration:
                .default(key: "KEY",reportingURL: .random, enableCrashReporting: true))
        var expectedBeacon: SessionProfileBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? SessionProfileBeacon {
                expectedBeacon = beacon
            }
        }

        // When
        Instana.current = Instana(session: session, monitors: Monitors(.mock, reporter: reporter))

        // Then
        AssertEqualAndNotNil(expectedBeacon?.state, SessionProfileBeacon.State.start)
    }

    func test_setup_and_dont_expect_SessionProfileBeacon_when_disabled() {
        // Given
        let config = InstanaConfiguration.mock
        let session: InstanaSession = .mock(configuration: config, collectionEnabled: false)
        var expectedBeacon: SessionProfileBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? SessionProfileBeacon {
                expectedBeacon = beacon
            }
        }

        // When
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // Then
        AssertFalse(Instana.collectionEnabled)
        AssertTrue(expectedBeacon == nil)
    }

    func test_setup_and_expect_SessionProfileBeacon_enabled_after_setup() {
        // Given
        let config = InstanaConfiguration.mock
        let session: InstanaSession = .mock(configuration: config, collectionEnabled: false)
        var expectedBeacon: SessionProfileBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? SessionProfileBeacon {
                expectedBeacon = beacon
            }
        }

        // When
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // Then
        AssertFalse(Instana.collectionEnabled)
        AssertTrue(expectedBeacon == nil)

        // When
        Instana.collectionEnabled = true

        // Then
        AssertTrue(expectedBeacon != nil)
    }

    func test_captureHTTP_request() {
        // Given
        let waitRequest = expectation(description: "test_captureHTTP_request")
        let session = InstanaSession.mock(configuration: .mock(httpCaptureConfig: .manual))
        var expectedBeacon: HTTPBeacon?
        var request = URLRequest(url: URL(string: "https://www.instana.com")!)
        request.httpMethod = "PUT"
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                expectedBeacon = beacon
                waitRequest.fulfill()
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        let sut = Instana.startCapture(request, viewName: "DetailView")
        sut.finish(response: HTTPURLResponse(url: .random, statusCode: 200, httpVersion: nil, headerFields: nil)!, error: nil)
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(sut.url, request.url)
        AssertEqualAndNotNil(sut.trigger, .manual)
        AssertEqualAndNotNil(expectedBeacon?.url, request.url)
        AssertEqualAndNotNil(expectedBeacon?.method, "PUT")
        AssertEqualAndNotNil(expectedBeacon?.responseCode, 200)
        AssertEqualAndNotNil(expectedBeacon?.viewName, "DetailView")
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

    func test_setUserID() {
        // Given
        let id = UUID().uuidString

        // When
        Instana.setUser(id: id)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.id, id)
        AssertTrue(Instana.current?.session.propertyHandler.properties.user?.email == nil)
        AssertTrue(Instana.current?.session.propertyHandler.properties.user?.name == nil)
    }

    func test_setUserEmail() {
        // Given
        let email = "email@example.com"

        // When
        Instana.setUser(email: email)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.id, "")
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.email, email)
        AssertTrue(Instana.current?.session.propertyHandler.properties.user?.name == nil)
    }

    func test_setUserName() {
        // Given
        let name = "John"

        // When
        Instana.setUser(name: name)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.id, "")
        AssertTrue(Instana.current?.session.propertyHandler.properties.user?.email == nil)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.name, name)
    }

    func test_setUser_update_existing() {
        // Given
        let id = UUID().uuidString
        let email = "email@example.com"
        let name = "John Appleseed"

        // When
        Instana.setUser(id: id)
        Instana.setUser(email: email)
        Instana.setUser(name: name)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.id, id)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.email, email)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.user?.name, name)
    }

    func test_setViewName() {
        // Given
        let viewName = "Some View"
        let session = InstanaSession.mock(configuration: config)
        let env = InstanaSession.mock(configuration: config)
        var didReport = false
        let reporter = MockReporter {beacon in
            didReport = (beacon is ViewChange) && beacon.viewName == viewName
        }
        Instana.current = Instana(session: session, monitors: Monitors(env, reporter: reporter))
        Instana.current?.session.propertyHandler.properties.view = ViewChange(viewName: "Old View")

        // When
        Instana.setView(name: viewName)

        // Then
        AssertTrue(didReport)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.viewName, viewName)
        AssertEqualAndNotNil(Instana.viewName, viewName)
    }

    func test_setViewName_shouldnotreport_if_view_not_changed() {
        // Given
        let viewName = "Some View"
        let session = InstanaSession.mock(configuration: config)
        var didReport = false
        let reporter = MockReporter {beacon in
            didReport = (beacon is ViewChange) && beacon.viewName == viewName
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))
        Instana.current?.session.propertyHandler.properties.view = ViewChange(viewName: viewName)

        // When
        Instana.setView(name: viewName)

        // Then
        AssertTrue(didReport == false)
    }

    func test_setViewInternal_negative() {
        // Given
        let session = InstanaSession.mock(configuration: .mock())

        var viewChangeBeaconCount = 0
        let reporter = MockReporter {
            if let _ = $0 as? ViewChange {
                viewChangeBeaconCount += 1
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.setView(name: "Old View Name") // will trigger ViewChange beacon
        Instana.current?.setViewInternal(name: nil) // nil view name should not trigger ViewChange beacon
        Thread.sleep(forTimeInterval: 1)

        // Then
        AssertEqualAndNotNil(viewChangeBeaconCount, 1)
    }

    func test_setMetaData() {
        // Given
        let given = ["Key": "Value", "Key2": "Value2"]

        // When
        Instana.setMeta(value: given["Key"]!, key: "Key")
        Instana.setMeta(value: given["Key2"]!, key: "Key2")

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.getMetaData(), given)
    }

    func test_setMetaData_value_exceeds_max() {
        // Given
        let max = MetaData.Max.lengthMetaValue
        let valid = "\((0..<max).map {_ in "A"}.joined())"
        let exceeds = "\((0..<max+10).map {_ in "C"}.joined())"

        // When
        Instana.setMeta(value: valid, key: "valid")
        Instana.setMeta(value: exceeds, key: "exceeds")

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.getMetaData()["valid"], valid)
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.getMetaData()["exceeds"], exceeds.cleanEscapeAndTruncate(at: max))
        AssertTrue(Instana.current?.session.propertyHandler.properties.getMetaData().count == 2)
    }

    func test_setMetaData_key_exceeds_max() {
        // Given
        let max = MetaData.Max.lengthMetaKey
        let valid = "\((0..<max).map {_ in "A"}.joined())"
        let exceeds = "\((0..<max+10).map {_ in "B"}.joined())"

        // When
        Instana.setMeta(value: "valid", key: valid)
        Instana.setMeta(value: "exceeds", key: exceeds)

        // Then
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.getMetaData()[valid], "valid")
        AssertEqualAndNotNil(Instana.current?.session.propertyHandler.properties.getMetaData()[exceeds.cleanEscapeAndTruncate(at: max)], "exceeds")
        AssertTrue(Instana.current?.session.propertyHandler.properties.getMetaData().count == 2)
    }

    func test_setMetaData_ignore_too_many_fields() {
        // Given
        let max = MetaData.Max.numberOfMetaEntries

        // When
        (0...MetaData.Max.numberOfMetaEntries).forEach { index in
            Instana.setMeta(value: "V-\(index)", key: "\(index)")
        }

        // Then
        let values = Array(Instana.current!.session.propertyHandler.properties.getMetaData().values)
        let keys = Array(Instana.current!.session.propertyHandler.properties.getMetaData().keys)
        AssertTrue(values.contains("V-0") == true)
        AssertTrue(values.contains("V-63") == true)
        AssertTrue(values.contains("V-64") == false)
        AssertTrue(keys.contains("63") == true)
        AssertTrue(keys.contains("64") == false)
        AssertTrue(Instana.current!.session.propertyHandler.properties.getMetaData().count == max)
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

    func test_reportCustom_AllValues() {
        // Given
        let name = "Custom Event"
        let session = InstanaSession.mock(configuration: config)
        let duration: Instana.Types.Milliseconds = 1
        let timestamp: Instana.Types.Milliseconds = 123
        let backendID = "B123"
        let error = NSError(domain: "Domain", code: 100, userInfo: nil)
        let meta = ["Key": "Value"]
        let viewName = "Some View"
        var didReport: CustomBeacon? = nil
        let reporter = MockReporter { didReport = $0 as? CustomBeacon }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.reportEvent(name: name, timestamp: timestamp, duration: duration, backendTracingID: backendID, error: error, meta: meta, viewName: viewName)

        // Then
        AssertTrue(didReport != nil)
        AssertEqualAndNotNil(didReport?.name, name)
        AssertEqualAndNotNil(didReport?.duration, Instana.Types.Milliseconds(duration))
        AssertEqualAndNotNil(didReport?.timestamp, Instana.Types.Milliseconds(timestamp))
        AssertEqualAndNotNil(didReport?.backendTracingID, backendID)
        AssertEqualAndNotNil((didReport?.error as NSError?), error)
        AssertEqualAndNotNil(didReport?.metaData, meta)
        AssertEqualAndNotNil(didReport?.viewName, viewName)
    }

    func test_reportCustom_just_name() {
        // Given
        let session = InstanaSession.mock(configuration: config)
        let waitFor = expectation(description: "test_reportCustom_just_name")
        let name = "Custom Event"
        var didReport: CustomBeacon? = nil
        let reporter = MockReporter {
            if let result = $0 as? CustomBeacon {
                didReport = result
                waitFor.fulfill()
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.reportEvent(name: name)
        wait(for: [waitFor], timeout: 2.0)

        // Then
        AssertTrue(didReport != nil)
        AssertEqualAndNotNil(didReport?.name, name)
        AssertTrue(didReport?.duration == nil)
        AssertTrue(didReport?.backendTracingID == nil)
        AssertTrue(didReport?.metaData == nil)
        AssertTrue(didReport?.error == nil)
        AssertEqualAndNotNil(didReport?.viewName, CustomBeaconDefaultViewNameID)
    }

    func test_reportCustom_view_nil() {
        // Given
        let session = InstanaSession.mock(configuration: config)
        let name = "Custom Event"
        var didReport: CustomBeacon? = nil
        let reporter = MockReporter {
            didReport = $0 as? CustomBeacon
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.reportEvent(name: name, viewName: nil)

        // Then
        AssertTrue(didReport != nil)
        AssertEqualAndNotNil(didReport?.name, name)
        AssertEqualAndNotNil(didReport?.viewName, CustomBeaconDefaultViewNameID)
    }

    func test_redactHTTPQueryMatchingRegex_default_manual() {
        // Given
        let url = URL(string: "https://www.instana.com/Key/?secret=secret&Password=test&KEY=123")!
        let waitReport = expectation(description: "test_redactHTTPQueryMatchingRegex_default")
        let session = InstanaSession.mock(configuration: .mock(httpCaptureConfig: .manual))
        var expectedBeacon: HTTPBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                expectedBeacon = beacon
                waitReport.fulfill()
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        // just using default behavior
        let marker = Instana.startCapture(url: url, method: "GET")
        marker.finish(.init(statusCode: 200))
        wait(for: [waitReport], timeout: 5.0)

        // Then
        XCTAssertEqual(expectedBeacon?.url.query, "secret=%3Credacted%3E&Password=%3Credacted%3E&KEY=%3Credacted%3E")
    }

    func test_redactHTTPQueryQueryMatchingRegex_explicit() {
        // Given
        let url = URL(string: "https://www.instana.com/Key/?Password=test&key=123&thePAssWord=123495")!
        let regex = try! NSRegularExpression(pattern: "password", options: [.caseInsensitive])
        let waitReport = expectation(description: "test_redactHTTPQueryQueryMatchingRegex_explicit")
        let session = InstanaSession.mock(configuration: .mock(httpCaptureConfig: .manual))
        var expectedBeacon: HTTPBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                expectedBeacon = beacon
                waitReport.fulfill()
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.redactHTTPQuery(matching: [regex])
        let marker = Instana.startCapture(url: url, method: "GET")
        marker.finish(.init(statusCode: 200))
        wait(for: [waitReport], timeout: 5.0)

        // Then
        XCTAssertEqual(expectedBeacon?.url.absoluteString, "https://www.instana.com/Key/?Password=%3Credacted%3E&key=123&thePAssWord=%3Credacted%3E")
    }

    func test_setCaptureHeaders() {
        // Given
        let url = URL(string: "https://www.instana.com/Key/?Password=test&key=123&thePAssWord=123495")!
        var request = URLRequest(url: url)
        request.addValue("should_be_monitored", forHTTPHeaderField: "x_key")
        request.addValue("should_not_be_monitored", forHTTPHeaderField: "password")
        let regex = try! NSRegularExpression(pattern: "X_Key", options: [.caseInsensitive])
        let waitReport = expectation(description: "test_setCaptureHeaders")
        let session = InstanaSession.mock(configuration: .mock(httpCaptureConfig: .manual))
        var expectedBeacon: HTTPBeacon?
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                expectedBeacon = beacon
                waitReport.fulfill()
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        // When
        Instana.setCaptureHeaders(matching: [regex])
        let marker = Instana.startCapture(request)
        marker.finish(.init(statusCode: 200))
        wait(for: [waitReport], timeout: 5.0)

        // Then
        XCTAssertEqual(expectedBeacon?.header?["x_key"], "should_be_monitored")
        XCTAssertEqual(expectedBeacon?.header?.count, 1)
    }

    func test_canSubscribeCrashReporting() {
        // When
        let canSubscribe = Instana.canSubscribeCrashReporting()

        // Then
        // These test cases need to run on iOS simulator 16.0 or above!
        XCTAssertTrue(canSubscribe)
    }

    func test_subscribeCrashReportings() {
        // Covers negative case of Monitors subscribeCrashReporting()
        Instana.subscribeCrashReporting()
    }

    func test_stopCrashReporting() {
        Instana.stopCrashReporting()
    }

    func test_cancelCrashReporting() {
        // case 1
        // When
        var cancelled = Instana.cancelCrashReporting()

        // Then
        // No operation going on, nothing to cancel
        XCTAssertFalse(cancelled)

        // case 2
        // When
        Instana.current?.monitors.metric = nil
        cancelled = Instana.cancelCrashReporting()

        // Then
        // Covers negative case when metric variable in Monitors is nil
        XCTAssertFalse(cancelled)

        // case 3
        // When
        Instana.current = nil
        cancelled = Instana.cancelCrashReporting()

        // Then
        // Covers negative case for empty current of Instana
        XCTAssertFalse(cancelled)
    }

    @available(*, deprecated)
    func test_setup_deprecated1() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        Instana.setup(key: key, reportingURL: reportingURL)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertTrue(Instana.collectionEnabled)
        AssertTrue(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)

        let config = Instana.current?.session.configuration
        XCTAssertNotNil(config)
        AssertEqualAndNotNil(config!.key, key)
        AssertEqualAndNotNil(config!.reportingURL, reportingURL)
        AssertEqualAndNotNil(config!.httpCaptureConfig, .automatic)
        AssertEqualAndNotNil(config!.slowSendInterval, 0.0)
        AssertEqualAndNotNil(config!.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
        AssertFalse(config!.monitorTypes.contains(.crash))

        let session = Instana.current?.session
        XCTAssertNotNil(session)
        AssertTrue(session!.collectionEnabled)
    }

    @available(*, deprecated)
    func test_setup_deprecated2() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!

        Instana.setup(key: key, reportingURL: reportingURL,
                      httpCaptureConfig: .manual,
                      collectionEnabled: true,
                      enableCrashReporting: true)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertTrue(Instana.collectionEnabled)
        AssertTrue(Instana.current!.session.collectionEnabled)
        AssertEqualAndNotNil(Instana.sessionID, Instana.current?.session.id.uuidString)

        let config = Instana.current?.session.configuration
        XCTAssertNotNil(config)
        AssertEqualAndNotNil(config!.key, key)
        AssertEqualAndNotNil(config!.reportingURL, reportingURL)
        AssertEqualAndNotNil(config!.httpCaptureConfig, .manual)
        AssertEqualAndNotNil(config!.slowSendInterval, 0.0)
        AssertEqualAndNotNil(config!.usiRefreshTimeIntervalInHrs, defaultUsiRefreshTimeIntervalInHrs)
        AssertTrue(config!.monitorTypes.contains(.crash))

        let session = Instana.current?.session
        XCTAssertNotNil(session)
        AssertTrue(session!.collectionEnabled)
    }

    func test_setup_not_called() {
        Instana.current = nil
        AssertFalse(Instana.collectionEnabled)
    }
    
    func test_setViewMetaCPInternal_called_negative(){
        // Given
        let session = InstanaSession.mock(configuration: .mock())

        var viewChangeBeaconCount = 0
        var capturedViewInternalMetaMap: [String: String]? = nil
        let reporter = MockReporter {
            if let viewChange = $0 as? ViewChange {
                capturedViewInternalMetaMap = viewChange.viewInternalCPMetaMap
                viewChangeBeaconCount += 1
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        let testViewInternalMetaMap = ["key1": "value1", "key2": "value2"]
        // When
        Instana.setViewMetaCPInternal(name: "ScreenName", viewInternalCPMetaMap:testViewInternalMetaMap)
        
        Instana.current?.setViewInternal(name: nil) // nil view name should not trigger ViewChange beacon
        Thread.sleep(forTimeInterval: 1)

        // Then
        AssertEqualAndNotNil(viewChangeBeaconCount, 0)
        AssertEqualAndNotNil(capturedViewInternalMetaMap, nil)
    }
    
    func test_setViewMetaCPInternal_called_positive(){
        // Given
        let session = InstanaSession.mock(configuration: .mock())

        var viewChangeBeaconCount = 0
        var capturedViewInternalMetaMap: [String: String]? = nil
        let reporter = MockReporter {
            if let viewChange = $0 as? ViewChange {
                capturedViewInternalMetaMap = viewChange.viewInternalCPMetaMap
                viewChangeBeaconCount += 1
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))

        let testViewInternalMetaMap = ["settings.route.name": "value1", "widget.name": "value2"]
        
        
        // When
        Instana.setViewMetaCPInternal(name: "ScreenName", viewInternalCPMetaMap:testViewInternalMetaMap)
        
        Instana.current?.setViewInternal(name: nil) // nil view name should not trigger ViewChange beacon
        Thread.sleep(forTimeInterval: 1)

        // Then
        AssertEqualAndNotNil(viewChangeBeaconCount, 1)
        AssertEqualAndNotNil(capturedViewInternalMetaMap, testViewInternalMetaMap)
    }
    
    func test_setViewMetaCPInternal_called_with_max_value_length(){
        // Given
        let session = InstanaSession.mock(configuration: .mock())

        var viewChangeBeaconCount = 0
        var capturedViewInternalMetaMap: [String: String]? = nil
        let reporter = MockReporter {
            if let viewChange = $0 as? ViewChange {
                capturedViewInternalMetaMap = viewChange.viewInternalCPMetaMap
                viewChangeBeaconCount += 1
            }
        }
        Instana.current = Instana(session: session, monitors: Monitors(session, reporter: reporter))
        var randomString = ""
        for _ in 0..<InstanaProperties.viewMaxLength+3 {
            let randomCharacter = Character(UnicodeScalar(UInt32.random(in: 65...90)) ?? "A") // A-Z
            randomString.append(randomCharacter)
        }

        let testViewInternalMetaMap = ["settings.route.name": randomString, "widget.name": "value2"]
        
        
        // When
        Instana.setViewMetaCPInternal(name: "ScreenName", viewInternalCPMetaMap:testViewInternalMetaMap)
        
        Instana.current?.setViewInternal(name: nil) // nil view name should not trigger ViewChange beacon
        Thread.sleep(forTimeInterval: 1)

        // Then
        AssertEqualAndNotNil(viewChangeBeaconCount, 1)
        AssertEqualAndNotNil(capturedViewInternalMetaMap?["settings.route.name"]?.count, InstanaProperties.viewMaxLength)
    }
}
