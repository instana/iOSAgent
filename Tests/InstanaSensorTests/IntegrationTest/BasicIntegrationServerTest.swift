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

    func test_Network() {
        // Need this as warm up for the webserver
        // when we remove this, our server is flaky
        let waitAddQueue = expectation(description: "add_queue")
        load() {_ in
            waitAddQueue.fulfill()
        }
        wait(for: [waitAddQueue], timeout: 2.0)
    }


    ////
    /// Test scenario
    /// 1 step: We are offline
    /// => Expect: No flush of the queue, beacons should be persisted
    /// 2 step: We create a new instance of the reporter (re-launch)
    /// => Expect: Old beacons should be still there
    /// 3 step: We come online and flush
    /// => Expect: Beacon queue should be empty
    func test_send_with_transmission_due_to_offline() {
        // Given
        var config = InstanaConfiguration.default(key: "KEY")
        let waitAddQueue = expectation(description: "add_queue")
        let waitFirstFlush = expectation(description: "expect_first_flush")
        let waitSecondFlush = expectation(description: "expect_second_flush")
        config.reportingURL = Defaults.baseURL
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        config.gzipReport = false
        let networkUtil = NetworkUtility.none
        reporter = Reporter(config, networkUtility: networkUtil)
        reporter.queue.removeAll() // Remove any old items
        let beacon = HTTPBeacon.createMock()

        // When
        var expectedResult: BeaconResult?
        reporter.submit(beacon) {
            waitAddQueue.fulfill()
        }
        wait(for: [waitAddQueue], timeout: 1.0)
        // Queue should have one item now!
        AssertTrue(reporter.queue.items.count == 1)

        reporter.completion = {result in
            expectedResult = result
            waitFirstFlush.fulfill()
        }

        // Then - Expect an error due no network connection
        wait(for: [waitFirstFlush], timeout: 2.0)
        guard let expectedError = expectedResult?.error as? InstanaError else {
            XCTFail("Expected InstanaError not found")
            return
        }
        AssertTrue(expectedError.code == InstanaError.Code.offline.rawValue)
        AssertTrue(reporter.queue.items.count == 1)

        // When creating a new instance of the reporter
        reporter = Reporter(config, networkUtility: networkUtil)
        reporter.completion = {_ in
            waitSecondFlush.fulfill()
        }

        // Then
        AssertTrue(reporter.queue.items.count == 1)

        // When going online again
        networkUtil.update(.wifi)

        // Then - expect a successful flush
        wait(for: [waitSecondFlush], timeout: 5.0)
        print(reporter.queue.items)
        AssertTrue(reporter.queue.items.count == 0)

        // Then Verify the server response - must be the same as we sent it
//        let serverReceivedtData = mockserver.connections.last?.receivedData ?? Data()
//        let serverReceivedHTTP = String(data: serverReceivedtData, encoding: .utf8)
//        do {
//            let responseBeacon = try CoreBeacon.create(from: serverReceivedHTTP ?? "")
//            let expectedBeacon = try CoreBeaconFactory(config).map(beacon)
//            AssertEqualAndNotNil(expectedBeacon, responseBeacon)
//        } catch (let error) {
//            XCTFail(error.localizedDescription)
//        }
    }
}
