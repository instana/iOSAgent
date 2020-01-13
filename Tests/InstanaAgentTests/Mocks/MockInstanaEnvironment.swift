import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaEnvironment {
    static var mock: InstanaEnvironment {
        let conf = InstanaConfiguration.default(key: "KEY", reportingURL: URL.random, httpCaptureConfig: .automatic)
        return mock(configuration: conf)
    }

    static func mock(configuration: InstanaConfiguration = .default(key: "KEY"),
                     sessionID: UUID? = nil,
                     metaData: [String: String]? = nil,
                     user: InstanaProperties.User? = nil,
                     currentView: String? = nil) -> InstanaEnvironment {
        let sessionID = sessionID ?? UUID()
        let metaData = metaData
        let propertyHandler = InstanaPropertyHandler()
        propertyHandler.properties = InstanaProperties(user: user, metaData: metaData, view: currentView)
        return InstanaEnvironment(configuration: configuration, propertyHandler: propertyHandler, sessionID: sessionID)
    }
}
