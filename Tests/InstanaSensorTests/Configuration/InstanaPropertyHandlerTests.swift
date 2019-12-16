import Foundation
import XCTest
@testable import InstanaSensor

class InstanaPropertyHandlerTests: XCTestCase {

    func test_setUser() {
        // Given
        let id = UUID().uuidString
        let email = "email@example.com"
        let name = "John Appleseed"
        let sut = InstanaPropertyHandler()

        // When
        sut.setUser(id: id, email: email, name: name)

        // Then
        AssertEqualAndNotNil(sut.properties.user?.id, id)
        AssertEqualAndNotNil(sut.properties.user?.email, email)
        AssertEqualAndNotNil(sut.properties.user?.name, name)
    }

    func test_setViewName() {
        // Given
        let viewName = "Some View"
        let sut = InstanaPropertyHandler()

        // When
        sut.setVisibleView(name: viewName)

        // Then
        AssertEqualAndNotNil(sut.properties.view, viewName)
    }

    func test_unsetVisibleView() {
        // Given
        let viewName = "Some View"
        let sut = InstanaPropertyHandler()

        // When
        sut.setVisibleView(name: viewName)

        // Then
        AssertEqualAndNotNil(sut.properties.view, viewName)

        // When
        sut.unsetVisibleView()

        // Then
        AssertTrue(sut.properties.view == nil)
    }

    func test_setMetaData() {
        // Given
        let given = ["Key": "Value", "Key2": "Value2"]
        let sut = InstanaPropertyHandler()

        // When
        sut.setMeta(value: given["Key"]!, key: "Key")
        sut.setMeta(value: given["Key2"]!, key: "Key2")

        // Then
        AssertEqualAndNotNil(sut.properties.metaData, given)
    }
}
