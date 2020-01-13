import XCTest
import Foundation
@testable import InstanaAgent

class InstanaPropertyHandlerTests: InstanaTestCase {

    func test_locking() {
        // Given
        var done = false
        let await = expectation(description: "test_locking")
        let queue = DispatchQueue(label: "background_queue", qos: .background, attributes: .concurrent)
        let propertyHandler = InstanaPropertyHandler()
        let propertyOne = InstanaProperties(user: InstanaProperties.User(id: "ID", email: "email@example.com", name: "Name"), metaData: nil, view: nil)
        let propertyTwo = InstanaProperties(user: InstanaProperties.User(id: "ID", email: "email@example.com", name: "Name"), metaData: nil, view: nil)
        let propertyThree = InstanaProperties(user: InstanaProperties.User(id: "ID2", email: "another@example.com", name: "Name"), metaData: nil, view: nil)
        let signal = {
            if !done {
                done = true
                await.fulfill()
            }
        }

        // When
        propertyHandler.properties = propertyOne
        queue.async {
            propertyHandler.properties = propertyTwo
            signal()
        }
        queue.async {
            propertyHandler.properties = propertyThree
            signal()
        }
        wait(for: [await], timeout: 0.5)

        // Then
        AssertTrue(propertyHandler.properties != propertyOne)
        AssertTrue(propertyHandler.properties.user != nil)
    }
}
