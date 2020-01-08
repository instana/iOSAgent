import Foundation
import XCTest
@testable import InstanaAgent

class InstanaEnvironmentTests: XCTestCase {

    func test_defaultInit() {
        // Given
        let propertyHandler = InstanaPropertyHandler()
        let config: InstanaConfiguration = .default(key: "Key")

        // When
        let sut = InstanaEnvironment(configuration: config, propertyHandler: propertyHandler)

        // Then
        AssertTrue(!sut.sessionID.uuidString.isEmpty)
        AssertEqualAndNotNil(sut.propertyHandler, propertyHandler)
        AssertEqualAndNotNil(sut.configuration, config)
    }
}
