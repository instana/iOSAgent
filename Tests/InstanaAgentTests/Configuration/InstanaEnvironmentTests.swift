//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class InstanaEnvironmentTests: InstanaTestCase {

    func test_defaultInit() {
        // Given
        let propertyHandler = InstanaPropertyHandler()

        // When
        let sut = InstanaSession(configuration: config, propertyHandler: propertyHandler)

        // Then
        AssertTrue(!sut.id.uuidString.isEmpty)
        AssertEqualAndNotNil(sut.propertyHandler, propertyHandler)
        AssertEqualAndNotNil(sut.configuration, config)
    }
}
