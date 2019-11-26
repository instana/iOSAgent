//  Created by Nikola Lajic on 2/1/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

extension Dictionary {
    mutating func set(ifNotNil value: Value?, forKey key: Key) {
        guard let value = value else { return }
        self[key] = value
    }
}
