import XCTest
@testable import InstanaAgent

class BeaconTests: InstanaTestCase {

    func test_Beacon_viewNameMaxBytes() {
        AssertTrue(InstanaProperties.viewMaxLength == 256)
    }

    func test_view_name_valid_length() {
        // Given
        let given = (0..<InstanaProperties.viewMaxLength).map {_ in "A"}.joined()

        // When
        let sut = Beacon(timestamp: 0, viewName: given)

        // Then
        AssertEqualAndNotNil(sut.viewName, given)
    }

    func test_view_name_valid_exceeds_max_length() {
        // Given
        let given = (0...InstanaProperties.viewMaxLength).map {_ in "A"}.joined()

        // When
        let sut = Beacon(timestamp: 0, viewName: given)

        // Then
        AssertEqualAndNotNil(sut.viewName, given.cleanEscapeAndTruncate(at: InstanaProperties.viewMaxLength))
    }
}
