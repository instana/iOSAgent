import XCTest
@testable import InstanaAgent

class InstanaSystemUtilsTests: InstanaTestCase {

    func test_AgentVersion() {
        // Then
        AssertTrue(InstanaSystemUtils.agentVersion == "1.1.11")
    }
}
