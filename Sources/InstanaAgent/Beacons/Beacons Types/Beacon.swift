//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

/// Base class for Beacon.
class Beacon: Identifiable {
    let id = Beacon.generateUniqueIdImpl()
    var timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970
    let viewName: String?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         viewName: String? = nil) {
        self.timestamp = timestamp
        self.viewName = InstanaProperties.validate(view: viewName)
    }

    // A hex encoded 64 bit random ID.
    static func generateUniqueIdImpl() -> String {
        let validIdCharacters = Array("0123456789abcdef")
        var result: String = ""
        for _ in 0 ..< 16 {
            let idx = Int.random(in: 0 ... 15)
            result += String(validIdCharacters[idx])
        }
        return result
    }
}

enum BeaconResult {
    case success
    case failure(Error)

    var error: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }
}
