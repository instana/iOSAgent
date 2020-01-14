import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaEnvironment {
    static var mock: InstanaEnvironment { mock(configuration: InstanaConfiguration.mock) }

    static func mock(configuration: InstanaConfiguration = .mock,
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
