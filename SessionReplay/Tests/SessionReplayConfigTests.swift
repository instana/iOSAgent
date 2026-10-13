//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay

@available(iOS 13.0, *)
class InstanaSessionReplayConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func test_init() throws {
        // Given
        let framePerSecond = 0.2
        let maskStrategy: MaskingStrategy = .mask_sensitive
        let maskingColor: UIColor = .green

        // When
        let config = InstanaSessionReplayConfig(framePerSecond: framePerSecond,
                                                maskStrategy: maskStrategy,
                                                maskingColor: maskingColor)
        // Then
        XCTAssertEqual(config.framePerSecond, framePerSecond)
        XCTAssertEqual(config.maskStrategy, maskStrategy)
        XCTAssertEqual(config.maskingColor, maskingColor)
        XCTAssertEqual(config.useFastScreenCapture, false)
    }

}
