//
//  File.swift
//  
//
//  Created by Christian Menschel on 27.11.19.
//

import Foundation
import XCTest
@testable import InstanaSensor

@available(iOS 12.0, *)
class BasicIntegrationServerTest: IntegrationTestCase {

    var reporter: BeaconReporter!

    func test_Network() {
        load() {result in
            XCTAssertNotNil(try? result.map {$0}.get())
        }
    }

    func test_send_and_receive_beaocns() {
        // Given
        let key = "KEY"
        let url = Defaults.baseURL
        reporter = BeaconReporter(reportingURL: url, key: key, transmissionDelay: 0.0, useGzip: false)
        let event = HTTPEvent.createMock()

        // When
        var expectedResult: EventResult?
        reporter.submit(event)
        reporter.completion = {result in
            expectedResult = result
            self.fulfilled()
        }
        wait(for: [expectation], timeout: 10.0)
        let serverReceivedtData = mockserver.connections.last?.receivedData ?? Data()
        let serverReceivedHTTP = String(data: serverReceivedtData, encoding: .utf8)

        // Then
        XCTAssertNotNil(expectedResult)
        XCTAssertNotNil(serverReceivedHTTP)

        do {
            let serverBeacon = try Beacon.create(from: serverReceivedHTTP ?? "")
            let expectedBeacon = try BeaconEventMapper(key: key).map(event)
            AssertEqualAndNotNil(expectedBeacon, serverBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }
}
