import Foundation

struct InstanaProperties: Equatable {
    struct User: Identifiable, Equatable {
        /// Unique identifier for the user
        var id: String
        /// User's email address
        var email: String?
        /// User's full name
        var name: String?
    }

    var user: User?
    var metaData: [String: String]?
    var view: String?
}

class InstanaPropertyHandler: NSObject {
    private var _unsafe_properties = InstanaProperties()
    private let lock = NSLock()
    var properties: InstanaProperties {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _unsafe_properties
        }
        set {
            lock.lock()
            _unsafe_properties = newValue
            lock.unlock()
        }
    }
}
