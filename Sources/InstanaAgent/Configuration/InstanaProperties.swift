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

extension InstanaProperties {
    var viewNameForCurrentAppState: String? {
        switch InstanaApplicationStateHandler.shared.state {
        case .active:
            return view
        case .background:
            return "Background"
        case .inactive:
            return "Inactive"
        @unknown default:
            return view
        }
    }
}

class InstanaPropertyHandler: NSObject {
    struct Const {
        static let maximumNumberOfMetaDataFields = 50
        static let maximumLengthPerMetaDataField = 256
    }

    private var unsafe_properties = InstanaProperties()
    private let lock = NSLock()
    var properties: InstanaProperties {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return unsafe_properties
        }
        set {
            lock.lock()
            unsafe_properties = newValue
            lock.unlock()
        }
    }

    func validate(value: String) -> Bool {
        if value.count > Const.maximumLengthPerMetaDataField {
            Instana.current?.session.logger.add("Instana: MetaData value reached maximum length (\(Const.maximumLengthPerMetaDataField)).", level: .warning)
            return false
        }
        return value.count <= Const.maximumLengthPerMetaDataField
    }

    func validate(keys: [String]) -> Bool {
        if keys.count > Const.maximumNumberOfMetaDataFields {
            // swiftlint:disable:next line_length
            Instana.current?.session.logger.add("Instana: MetaData reached maximum number (\(Const.maximumNumberOfMetaDataFields)) of valid fields.", level: .warning)
            return false
        }
        return true
    }
}
