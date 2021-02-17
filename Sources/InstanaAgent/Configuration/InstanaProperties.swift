//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

typealias MetaData = [String: String]

struct InstanaProperties: Equatable {
    struct User: Equatable {
        static let userValueMaxLength = 128

        /// Unique identifier for the user
        var id: String {
            didSet { id = Self.validate(value: id) ?? id }
        }

        /// User's email address
        var email: String? {
            didSet { email = Self.validate(value: email) }
        }

        /// User's full name
        var name: String? {
            didSet { name = Self.validate(value: name) }
        }

        init(id: String, email: String?, name: String?) {
            self.id = Self.validate(value: id) ?? id
            self.email = Self.validate(value: email)
            self.name = Self.validate(value: name)
        }

        static func validate(value: String?) -> String? {
            guard let value = value else { return nil }
            return value.cleanEscapeAndTruncate(at: userValueMaxLength)
        }
    }

    var user: User?
    private(set) var metaData = MetaData()

    static let viewMaxLength = 256
    var view: String? {
        didSet { view = Self.validate(view: view) }
    }

    init(user: User? = nil, view: String? = nil) {
        self.user = user
        self.view = Self.validate(view: view)
    }

    mutating func appendMetaData(_ key: String, _ value: String) {
        let key = MetaData.validate(key: key)
        let value = MetaData.validate(value: value)
        if metaData.count < MetaData.Max.numberOfMetaEntries {
            metaData[key] = value
        }
    }

    static func validate(view: String?) -> String? {
        guard let value = view else { return nil }
        return value.cleanEscapeAndTruncate(at: viewMaxLength)
    }
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
        }
    }
}

class InstanaPropertyHandler: NSObject {
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
}

extension MetaData {
    struct Max {
        static let numberOfMetaEntries = 64
        static let lengthMetaValue = 256
        static let lengthMetaKey = 98
    }

    static func validate(value: String) -> String {
        if value.count > Max.lengthMetaValue {
            Instana.current?.session.logger.add("Instana: MetaData value reached maximum length (\(Max.lengthMetaValue)) Truncating value.", level: .warning)
        }
        return value.cleanEscapeAndTruncate(at: Max.lengthMetaValue)
    }

    static func validate(key: String) -> String {
        if key.count > Max.lengthMetaKey {
            Instana.current?.session.logger.add("Instana: MetaData key reached maximum length (\(Max.lengthMetaKey)) Truncating key.", level: .warning)
        }
        return key.cleanEscapeAndTruncate(at: Max.lengthMetaKey)
    }
}
