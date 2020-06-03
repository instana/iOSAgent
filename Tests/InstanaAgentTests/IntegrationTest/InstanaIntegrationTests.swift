import Foundation
import XCTest
@testable import InstanaAgent

// Intgration Testing of the main Instana public methods and properties

class InstanaIntegrationTests: InstanaTestCase {

    // MARK: Setup
    func test_setup() {
        // Given
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        let reporter = createInstanaReporter(beaconType: .sessionStart, waitFor) { sentBeacon = $0 }

        // When
        Instana.current = Instana(session: session, configuration: session.configuration, monitors: Monitors(session, reporter: reporter))

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertTrue(sentBeacon?.t == BeaconType.sessionStart)
    }

    func test_auto_http_capture() {
        // Given
        let waitFor = expectation(description: "Wait For")
        let url = URL(string: "https://127.0.0.1/instana/some")!
        var sentBeacon: CoreBeacon?
        let urlSession = URLSession(configuration: .default)
        let reporter = createInstanaReporter(beaconType: .httpRequest, waitFor) { sentBeacon = $0 }
        Instana.current = Instana(session: session, configuration: config, monitors: Monitors(session, reporter: reporter))
        let request = URLRequest(url: url)

        // When
        urlSession.dataTask(with: request) { (data, response, error) in
        }.resume()

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertTrue(sentBeacon?.t == BeaconType.httpRequest)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hp, url.path)
        AssertEqualAndNotNil(sentBeacon?.hs, "-1")
        AssertEqualAndNotNil(sentBeacon?.hu, url.absoluteString)
        AssertTrue(sentBeacon?.ebs == nil)
        AssertTrue(sentBeacon?.dbs == nil)
        AssertTrue(sentBeacon?.trs == nil)
    }

    func test_manual_http_capture() {
        // Given
        let waitFor = expectation(description: "Wait For")
        let url = URL(string: "https://127.0.0.1/instana/some")!
        var sentBeacon: CoreBeacon?
        let urlSession = URLSession(configuration: .default)
        let config = InstanaConfiguration.default(key: "Key", reportingURL: .random, httpCaptureConfig: .manual)
        let session = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler())
        let reporter = createInstanaReporter(beaconType: .httpRequest, waitFor) { sentBeacon = $0 }
        Instana.current = Instana(session: session, configuration: config, monitors: Monitors(session, reporter: reporter))
        let request = URLRequest(url: url)

        // When
        let marker = Instana.startCapture(request)
        urlSession.dataTask(with: request) { (data, response, error) in
            marker.set(responseSize: HTTPMarker.Size(header: 1, body: 2, bodyAfterDecoding: 3))
            marker.finish(response: response, error: error)
        }.resume()

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertTrue(sentBeacon?.t == BeaconType.httpRequest)
        AssertEqualAndNotNil(sentBeacon?.hm, "GET")
        AssertEqualAndNotNil(sentBeacon?.hp, url.path)
        AssertEqualAndNotNil(sentBeacon?.hs, "-1")
        AssertEqualAndNotNil(sentBeacon?.hu, url.absoluteString)
        AssertEqualAndNotNil(sentBeacon?.ebs, "2")
        AssertEqualAndNotNil(sentBeacon?.dbs, "3")
        AssertEqualAndNotNil(sentBeacon?.trs, "3")
    }

    // MARK: Meta
    func test_set_meta_delayed() {
        // Given
        let value = "some@example.com"
        let key = "User"
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .viewChange, waitFor) { sentBeacon = $0 }

        // When
        Instana.setMeta(value: value, key: key)
        Instana.setView(name: "Something")

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertEqualAndNotNil(sentBeacon?.m?[key], value)
    }

    // MARK: User
    func test_set_user_delayed() {
        // Given
        let email = "some@example.com"
        let name = "User name"
        let userID = UUID().uuidString
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .viewChange, waitFor) { sentBeacon = $0 }

        // When
        Instana.setUser(id: userID, email: email, name: name)
        Instana.setView(name: "Something")

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertEqualAndNotNil(sentBeacon?.ui, userID)
        AssertEqualAndNotNil(sentBeacon?.ue, email)
        AssertEqualAndNotNil(sentBeacon?.un, name)
    }

    // MARK: ViewName
    func test_Instana_set_viewName() {
        // Given
        let viewName = "Some View"
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .viewChange, waitFor) { sentBeacon = $0 }

        // When
        Instana.setView(name: viewName)

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertEqualAndNotNil(sentBeacon?.v, viewName)
        AssertTrue(sentBeacon?.v != nil)
    }

    // MARK: Custom Event
    func test_Instana_report_custom_event() {
        // Given
        let waitFor = expectation(description: "Wait For")
        let timestamp: Int64 = 1234
        let name = "Some name"
        let duration: Int64 = 12
        let backendTracingID = "BackendID"
        let error: NSError = InstanaError(code: .invalidResponse, description: "Some")
        let mKey = "Key"
        let mValue = "Value"
        let viewName = "View"
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .custom, waitFor) { sentBeacon = $0 }
        session.propertyHandler.properties.metaData = ["Key": "MyValue"]
        session.propertyHandler.properties.view = "My View"

        // When
        Instana.reportEvent(name: name, timestamp: timestamp, duration: duration, backendTracingID: backendTracingID, error: error, meta: [mKey: mValue], viewName: viewName)

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertEqualAndNotNil(sentBeacon?.v, viewName) // Overrides the default set in session.propertyHandler.properties
        AssertEqualAndNotNil(sentBeacon?.bt, backendTracingID)
        AssertEqualAndNotNil(sentBeacon?.ti, "\(timestamp)")
        AssertEqualAndNotNil(sentBeacon?.d, "\(duration)")
        AssertEqualAndNotNil(sentBeacon?.cen, name)
        AssertEqualAndNotNil(sentBeacon?.ec, "\(1)")
        AssertEqualAndNotNil(sentBeacon?.et, "InstanaError")
        AssertEqualAndNotNil(sentBeacon?.em, "Error Domain=com.instana.ios.agent.error Code=2 \"Some\" UserInfo={NSLocalizedDescription=Some}")
        AssertEqualAndNotNil(sentBeacon?.m?[mKey], mValue) // Overrides the default set in session.propertyHandler.properties
    }

    func test_Instana_report_custom_event_current_viewName() {
        // Given
        let name = "Some name"
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .custom, waitFor) { sentBeacon = $0 }

        // When
        Instana.setView(name: "View")
        Instana.reportEvent(name: name)

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertEqualAndNotNil(sentBeacon?.cen, name)
        AssertTrue(Instana.viewName != nil)
        AssertEqualAndNotNil(sentBeacon?.v, Instana.viewName)
    }

    func test_Instana_report_custom_event_no_viewName() {
        // Given
        let name = "Some name"
        let waitFor = expectation(description: "Wait For")
        var sentBeacon: CoreBeacon?
        createInstanaReporter(beaconType: .custom, waitFor) { sentBeacon = $0 }

        // When
        Instana.reportEvent(name: name, viewName: nil)

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertTrue(sentBeacon != nil)
        AssertEqualAndNotNil(sentBeacon?.cen, name)
        AssertTrue(sentBeacon?.v == nil)
    }

    func test_default_values() {
        // Given
        let waitFor = expectation(description: "Wait For")
        var serverBeacon: CoreBeacon!
        createInstanaReporter(beaconType: .custom, waitFor) { serverBeacon = $0 }
        session.propertyHandler.properties.metaData = ["Key": "MyValue"]
        session.propertyHandler.properties.user = .init(id: "UserID", email: "email@example.com", name: "User Name")
        session.propertyHandler.properties.view = "My View"

        // When
        Instana.reportEvent(name: "Event name", viewName: "my view")

        // Then
        wait(for: [waitFor], timeout: 5.0)
        AssertEqualAndNotNil(serverBeacon.ab, InstanaSystemUtils.applicationBuildNumber)
        AssertEqualAndNotNil(serverBeacon.av, InstanaSystemUtils.applicationVersion)
        AssertEqualAndNotNil(serverBeacon.agv, InstanaSystemUtils.agentVersion)
        AssertEqualAndNotNil(serverBeacon.bi, "com.apple.dt.xctest.tool")
        AssertEqualAndNotNil(serverBeacon.ct, "Wifi")
        AssertEqualAndNotNil(serverBeacon.t, BeaconType.custom)
        AssertEqualAndNotNil(serverBeacon.cn, "None")
        AssertEqualAndNotNil(serverBeacon.dma, "Apple")
        AssertEqualAndNotNil(serverBeacon.cen, "Event name")
        AssertEqualAndNotNil(serverBeacon.v, "my view") // Overrides the original
        AssertEqualAndNotNil(serverBeacon.vh, "\(Int(UIScreen.main.nativeBounds.size.height))")
        AssertEqualAndNotNil(serverBeacon.vw, "\(Int(UIScreen.main.nativeBounds.size.width))")
        AssertEqualAndNotNil(serverBeacon.osv, InstanaSystemUtils.systemVersion)
        AssertEqualAndNotNil(serverBeacon.osn, "iOS")
        AssertEqualAndNotNil(serverBeacon.p, "iOS")
        AssertEqualAndNotNil(serverBeacon.m, ["Key": "MyValue"])
        AssertEqualAndNotNil(serverBeacon.ui, "UserID")
        AssertEqualAndNotNil(serverBeacon.ue, "email@example.com")
        AssertEqualAndNotNil(serverBeacon.un, "User Name")
        AssertEqualAndNotNil(serverBeacon.ul, "en")
    }

    // MARK: Helper
    @discardableResult
    func createInstanaReporter(session: InstanaSession? = nil, beaconType: BeaconType, _ waitFor: XCTestExpectation, _ reporterCompletion: @escaping (CoreBeacon) -> Void) -> Reporter {
        let thesession = session ?? self.session!
        let reporter = Reporter(thesession, networkUtility: .wifi) {request, completion   in
            let serverReceivedHTTP = String(data: request.httpBody ?? Data(), encoding: .utf8)
            let sentBeacon = try? CoreBeacon.create(from: serverReceivedHTTP ?? "")
            if let sentBeacon = sentBeacon, sentBeacon.t == beaconType {
                completion(.success(statusCode: 200))
                reporterCompletion(sentBeacon)
            }
        }
        Instana.current = Instana(session: thesession, configuration: thesession.configuration, monitors: Monitors(thesession, reporter: reporter))
        reporter.completionHandler.append {_ in
            DispatchQueue.main.async {
                waitFor.fulfill()
            }
        }
        return reporter
    }
}
