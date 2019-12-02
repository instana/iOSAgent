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

    func test_Network() {
        load() {result in
            XCTAssertNotNil(try? result.map {$0}.get())
        }
    }

   // func test_send_beaocns() {
//        // Given
//        let url = Defaults.baseURL
//        let reporter = BeaconReporter(reportingURL: url, transmissionDelay: 0.0) { _, _, _ in}
//        let event = HTTPEvent.createMock()
////        event.no
//        // When
//        reporter.submit(event)
//
//        // Then
//
//
//        wait(for: [expectation], timeout: 10.0)
  //  }
}
