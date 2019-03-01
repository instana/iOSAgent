//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest

extension XCTestCase {
    func selfCleaningTempFileURL(name: String, file: StaticString = #file, line: UInt = #line) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        
        addTeardownBlock {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), file: file, line: line)
                }
            } catch {
                XCTFail("Error while deleting temporary file: \(error)", file: file, line: line)
            }
        }
        return url
    }
}
