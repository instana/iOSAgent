//
//  InstanaTests.swift
//  
//
//  Created by Christian Menschel on 04.12.19.
//

import Foundation
import XCTest
@testable import InstanaSensor

class InstanaTests: XCTestCase {

    func test_setup() {
        // Given
        let key = "KEY"
        let reportingURL = URL(string: "http://www.instana.com")!
        let reportingType: ReportingType = .manual

        // When
        Instana.setup(key: key, reportingURL: reportingURL, reportingType: reportingType)

        // Then
        AssertEqualAndNotNil(Instana.key, key)
        AssertEqualAndNotNil(Instana.reportingURL, reportingURL)
        AssertEqualAndNotNil(Instana.current?.environment.configuration, .default(key: key, reportingURL: reportingURL, reportingType: reportingType))
    }

    func test_markHTTP_URL() {
        // Given
        let waitRequest = expectation(description: "test_markHTTP_URL")
        var excpectedSubmittedBeacon: HTTPBeacon?
        let method = "GET"
        let url = URL(string: "https://www.instana.com")!
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                excpectedSubmittedBeacon = beacon
                waitRequest.fulfill()
            }
        }
        Instana.current = Instana(configuration: .default(key: "KEY"), monitors: Monitors(.mock, reporter: reporter))

        // When
        let sut = Instana.markHTTP(url, method: method)
        sut.finished(responseCode: 200)
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(sut.url, url)
        AssertEqualAndNotNil(sut.trigger, .manual)
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.url, url)
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.method, method)
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.responseCode, 200)
    }

    func test_markHTTP_request() {
        // Given
        let waitRequest = expectation(description: "test_markHTTP_request")
        var excpectedSubmittedBeacon: HTTPBeacon?
        var request = URLRequest(url: URL(string: "https://www.instana.com")!)
        request.httpMethod = "PUT"
        let reporter = MockReporter {
            if let beacon = $0 as? HTTPBeacon {
                excpectedSubmittedBeacon = beacon
                waitRequest.fulfill()
            }
        }
        Instana.current = Instana(configuration: .default(key: "KEY"), monitors: Monitors(.mock, reporter: reporter))

        // When
        let sut = Instana.markHTTP(request)
        sut.finished(responseCode: 200)
        wait(for: [waitRequest], timeout: 1.0)

        // Then
        AssertEqualAndNotNil(sut.url, request.url)
        AssertEqualAndNotNil(sut.trigger, .manual)
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.url, request.url)
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.method, "PUT")
        AssertEqualAndNotNil(excpectedSubmittedBeacon?.responseCode, 200)
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
}
