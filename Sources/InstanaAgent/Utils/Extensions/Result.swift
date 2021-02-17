//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

extension Swift.Result {
    var error: Failure? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }
}
