//  Created by Nikola Lajic on 3/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest

extension Mirror {
    func typedChild<T>(at path: String, type: T.Type, file: StaticString = #file, line: UInt = #line) -> T? {
        if let child = descendant(path) {
            let grandchildren = Mirror(reflecting: child).children
            if grandchildren.count == 0 {
                return nil
            }
            else if let typedChild = grandchildren.first?.value as? T {
                return typedChild
            }
            else {
                XCTFail("Mismatched type for child at path: '\(path)'", file: file, line: line)
            }
        }
        return nil
    }
}
