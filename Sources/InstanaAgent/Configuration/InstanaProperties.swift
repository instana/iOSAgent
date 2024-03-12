//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

typealias MetaData = [String: String]
typealias HTTPHeader = [String: String]

// Make this a reference type to avoid a copy for concurrency
class InstanaProperties {
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
            PreviousSession.persistUser(id: self.id, email: self.email, name: self.name)
        }

        static func validate(value: String?) -> String? {
            guard let value = value else { return nil }
            return value.cleanEscapeAndTruncate(at: userValueMaxLength)
        }
    }

    var user: User?
    private var metaData = MetaData()
    private let queueMetaData = DispatchQueue(label: "com.instana.ios.agent.metadata", attributes: .concurrent)

    static let viewMaxLength = 256

    var view: ViewChange? {
        didSet {
            PreviousSession.persistView(viewName: view?.viewName)
        }
    }

    var viewName: String? {
        return view?.viewName
    }

    init(user: User? = nil, view: String? = nil) {
        self.user = user
        self.view = ViewChange(viewName: view, accessibilityLabel: nil, navigationItemTitle: nil, className: nil)
    }

    func appendMetaData(_ key: String, _ value: String) {
        let key = MetaData.validate(key: key)
        let value = MetaData.validate(value: value)
        queueMetaData.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }
            if self.metaData.count < MetaData.Max.numberOfMetaEntries {
                self.metaData[key] = value
            }
        }
    }

    func getMetaData() -> MetaData {
        return queueMetaData.sync {
            self.metaData
        }
    }
}

extension InstanaProperties {
    var viewNameForCurrentAppState: String? {
        switch InstanaApplicationStateHandler.shared.state {
        case .active:
            return viewName
        case .background:
            return "Background"
        case .inactive:
            return "Inactive"
        }
    }
}

class InstanaPropertyHandler: NSObject {
    @Atomic var properties = InstanaProperties()
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
