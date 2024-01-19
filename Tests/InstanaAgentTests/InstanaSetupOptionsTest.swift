//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class HybridAgentOptionsTests: XCTestCase {
    func test_init() {
        let mco = HybridAgentOptions(id:"f", version:"3.0.6")
        AssertEqualAndNotNil(mco.id, "f")
        AssertEqualAndNotNil(mco.version, "3.0.6")

        let mcoTooLong = HybridAgentOptions(id:"react-native-agent", version:"2.0.3")
        AssertEqualAndNotNil(mcoTooLong.id, "react-native-age")
        AssertEqualAndNotNil(mcoTooLong.version, "2.0.3")

        let mcoMisConfiged = HybridAgentOptions(id:"", version:"")
        AssertEqualAndNotNil(mcoMisConfiged.id, "")
        AssertEqualAndNotNil(mcoMisConfiged.version, "")
    }
}
