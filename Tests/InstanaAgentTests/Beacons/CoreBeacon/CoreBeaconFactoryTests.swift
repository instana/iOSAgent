import Foundation
import XCTest
@testable import InstanaAgent

class CoreBeaconFactoryTests: XCTestCase {

    var config: InstanaConfiguration!

    override func setUp() {
        super.setUp()
        config = InstanaConfiguration.default(key: "KEY")
    }

    func test_undefined_beacon_type() {
        // Given
        let beacon = Beacon()
        let mapper = CoreBeaconFactory(InstanaEnvironment.mock)

        // When
        XCTAssertThrowsError(try mapper.map(beacon)) {error in
            // Then
            XCTAssertEqual((error as? InstanaError)?.code, InstanaError.Code.unknownType.rawValue)
        }
    }

    /// All other beacon mapping will be tested in the 'Beacon Types' Tests (i.e. HTTPBeaconTests)
}
