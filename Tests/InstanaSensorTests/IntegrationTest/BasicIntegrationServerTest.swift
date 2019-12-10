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
        let waitAddQueue = expectation(description: "add_queue")
        let waitFlushQueue = expectation(description: "flush")
        var config = InstanaConfiguration.default(key: "KEY")
        config.reportingURL = Defaults.baseURL
        config.transmissionDelay = 0.0
        config.transmissionLowBatteryDelay = 0.0
        config.gzipReport = false
        reporter = Reporter(config, networkUtility: .wifi)
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
            waitFlushQueue.fulfill()
        }

        wait(for: [waitFlushQueue], timeout: 10.0)
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
        wait(for: [waitFirstFlush], timeout: 10.0)
        AssertTrue(expectedResult != nil)
        AssertTrue((expectedResult?.error as! InstanaError).code == InstanaError.Code.offline.rawValue)
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
    }
}
