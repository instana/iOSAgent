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

    var reporter: Reporter!

    func xtest_Network() {
        load() {result in
            XCTAssertNotNil(try? result.map {$0}.get())
        }
    }

    func test_send_and_receive_beaocns() {
        // Given
        var config = InstanaConfiguration.default(key: "KEY")
        config.reportingURL = Defaults.baseURL
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        config.gzipReport = false
        reporter = Reporter(config)
        let beacon = HTTPBeacon.createMock()

        // When
        var expectedResult: BeaconResult?
        reporter.submit(beacon)

        // Queue should have one item now!
        AssertTrue(reporter.queue.items.count == 1)

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
        AssertTrue(reporter.queue.items.isEmpty)

        do {
            let responseBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
            let expectedBeacon = try CoreBeaconFactory(config).map(beacon)
            AssertEqualAndNotNil(expectedBeacon, responseBeacon)
        } catch (let error) {
            XCTFail(error.localizedDescription)
        }
    }
}
