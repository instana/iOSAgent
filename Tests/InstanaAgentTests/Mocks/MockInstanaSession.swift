//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

extension InstanaSession {
    static var mock: InstanaSession { mock(configuration: .mock(maxRetries: 0)) }
    static var mockWithManualHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .manual))}
    static var mockWithAutomaticHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .automatic))}
    static var mockWithAutomaticAndManualHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .automaticAndManual))}
    static var mockWithNoneHTTPCapture: InstanaSession { mock(configuration: InstanaConfiguration.mock(key: "", reportingURL: .random, httpCaptureConfig: .none))}

    static func mock(configuration: InstanaConfiguration = .mock,
                     sessionID: UUID? = nil,
                     metaData: MetaData = [:],
                     user: InstanaProperties.User? = nil,
                     currentView: String? = nil,
                     collectionEnabled: Bool = true,
                     previousSession: PreviousSession? = nil) -> InstanaSession {
        let sessionID = sessionID ?? UUID()
        let metaData = metaData
        let propertyHandler = InstanaPropertyHandler()
        let properties = InstanaProperties(user: user, view: currentView)
        metaData.forEach { (key, value) in
            properties.appendMetaData(key, value)
        }
        propertyHandler.properties = properties

        return InstanaSession(configuration: configuration, propertyHandler: propertyHandler, sessionID: sessionID, collectionEnabled: collectionEnabled)
    }
}
