
import Foundation

extension Swift.Result {
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}
