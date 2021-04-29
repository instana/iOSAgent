//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

// Intgration Testing of the main Instana public methods and properties

class InstanaIntegrationTests: InstanaTestCase {

    // Testing Singletons is hard, we test only one

    func test_auto_http_capture() {
        // Given
        let waitFor = expectation(description: "Wait For")
        let url = URL(string: "https://127.0.0.1/instana/some")!
        var sentBeacon: CoreBeacon?
        let config = InstanaConfiguration.mock(key: "KEY", reportingURL: .random, httpCaptureConfig: .automatic)
        let session = InstanaSession.mock(configuration: config)
        let reporter = createInstanaReporter(session: session, beaconType: .httpRequest, waitFor) { sentBeacon = $0 }

        // When
        Instana.current = Instana(session: session, configuration: config, monitors: Monitors(session, reporter: reporter))
        session.propertyHandler.properties.appendMetaData("Key", "Value")
        session.propertyHandler.properties.view = "My View"
        session.propertyHandler.properties.user = .init(id: "UserID", email: "email@example.com", name: "User Name")
        let request = URLRequest(url: url)
        let urlSession = URLSession(configuration: .default)
        urlSession.dataTask(with: request) { (data, response, error) in
        }.resume()

        // Then
        wait(for: [waitFor], timeout: 10.0)
        AssertTrue(sentBeacon != nil)
        AssertTrue(sentBeacon?.t == BeaconType.httpRequest)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hp, url.path)
        AssertEqualAndNotNil(sentBeacon?.hs, "-1")
        AssertEqualAndNotNil(sentBeacon?.hu, url.absoluteString)
        AssertTrue(sentBeacon?.ebs == nil)
        AssertTrue(sentBeacon?.dbs == nil)
        AssertTrue(sentBeacon?.trs == nil)

        AssertEqualAndNotNil(sentBeacon?.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(sentBeacon?.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(sentBeacon?.agv, InstanaSystemUtils.agentVersion)
        AssertEqualAndNotNil(sentBeacon?.bi, "com.apple.dt.xctest.tool")
        AssertEqualAndNotNil(sentBeacon?.ct, "wifi")
        AssertEqualAndNotNil(sentBeacon?.t, BeaconType.httpRequest)
        AssertEqualAndNotNil(sentBeacon?.cn, "None")
        AssertEqualAndNotNil(sentBeacon?.dma, "Apple")
        AssertEqualAndNotNil(sentBeacon?.cen, nil)
        AssertEqualAndNotNil(sentBeacon?.v, "My View") // Overrides the original
        AssertEqualAndNotNil(sentBeacon?.vh, "\(Int(UIScreen.main.bounds.size.height))")
        AssertEqualAndNotNil(sentBeacon?.vw, "\(Int(UIScreen.main.bounds.size.width))")
        AssertEqualAndNotNil(sentBeacon?.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(sentBeacon?.osn, "iOS")
        AssertEqualAndNotNil(sentBeacon?.p, "iOS")
        AssertEqualAndNotNil(sentBeacon?.m, ["Key": "Value"])
        AssertEqualAndNotNil(sentBeacon?.ui, "UserID")
        AssertEqualAndNotNil(sentBeacon?.ue, "email@example.com")
        AssertEqualAndNotNil(sentBeacon?.un, "User Name")
        AssertEqualAndNotNil(sentBeacon?.ul, "en")
    }

    // MARK: Helper
    @discardableResult
    func createInstanaReporter(session: InstanaSession, beaconType: BeaconType, _ waitFor: XCTestExpectation, _ reporterCompletion: @escaping (CoreBeacon) -> Void) -> Reporter {
        let reporter = Reporter(session, networkUtility: .wifi) {request, completion   in
            let serverReceivedHTTP = String(data: request.httpBody ?? Data(), encoding: .utf8)
            let sentBeacon = try? CoreBeacon.create(from: serverReceivedHTTP ?? "")
            if let sentBeacon = sentBeacon, sentBeacon.t == beaconType {
                completion(.success(statusCode: 200))
                reporterCompletion(sentBeacon)
            }
        }
        reporter.completionHandler.append {_ in
            DispatchQueue.main.async {
                waitFor.fulfill()
            }
        }
        return reporter
    }
}
