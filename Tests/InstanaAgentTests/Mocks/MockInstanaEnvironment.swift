import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaSession {
    static var mock: InstanaSession { mock(configuration: InstanaConfiguration.mock) }
    static var mockWithManualHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .manual))}
    static var mockWithAutomaticHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .automatic))}
    static var mockWithNoneHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .none))}

    static func mock(configuration: InstanaConfiguration = .mock,
                     sessionID: UUID? = nil,
                     metaData: MetaData = [:],
                     user: InstanaProperties.User? = nil,
                     currentView: String? = nil) -> InstanaSession {
        let sessionID = sessionID ?? UUID()
        let metaData = metaData
        let propertyHandler = InstanaPropertyHandler()
        var properties = InstanaProperties(user: user, view: currentView)
        metaData.forEach { (key, value) in
            properties.appendMetaData(key, value)
        }
        propertyHandler.properties = properties

        return InstanaSession(configuration: configuration, propertyHandler: propertyHandler, sessionID: sessionID)
    }
}
