//  Created by Nikola Lajic on 3/8/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import Instana

class InstanaURLSessionConfigurationExtensionsTests: XCTestCase {

    func test_wifiConfiguration_disabledCellularAccess() {
        XCTAssertFalse(URLSessionConfiguration.wifi.allowsCellularAccess)
    }
}
