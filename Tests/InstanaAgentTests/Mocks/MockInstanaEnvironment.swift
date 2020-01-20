import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaSession {
    static var mock: InstanaSession { mock(configuration: InstanaConfiguration.mock) }

    static func mock(configuration: InstanaConfiguration = .mock,
                     sessionID: UUID? = nil,
                     metaData: [String: String]? = nil,
                     user: InstanaProperties.User? = nil,
                     currentView: String? = nil) -> InstanaSession {
        let sessionID = sessionID ?? UUID()
        let metaData = metaData
        let propertyHandler = InstanaPropertyHandler()
        propertyHandler.properties = InstanaProperties(user: user, metaData: metaData, view: currentView)
        return InstanaSession(configuration: configuration, propertyHandler: propertyHandler, sessionID: sessionID)
    }
}
