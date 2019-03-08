//  Created by Nikola Lajic on 3/8/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

extension URLSessionConfiguration {
    class var wifi: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = false
        return configuration
    }
}
