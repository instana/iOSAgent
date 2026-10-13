//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation

@_spi(Internal)
public class UserEventBeacon: Beacon, Codable {
    var eventType: String
    var eventValue: String?
    var eventValueKey: String?
    var viewClassName: String?
    var viewId: String?

    private enum CodingKeys: String, CodingKey {
        case timestamp = "ti"
        case eventType = "evt"
        case eventValue = "evv" // internal only
        case eventValueKey = "evk" // internal only
        case viewClassName = "vn"
        case viewId = "vi"
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decode(Instana.Types.Milliseconds.self, forKey: .timestamp)
        eventType = try container.decode(String.self, forKey: .eventType)
        eventValue = try container.decodeIfPresent(String.self, forKey: .eventValue)
        eventValueKey = try container.decodeIfPresent(String.self, forKey: .eventValueKey)
        viewClassName = try container.decodeIfPresent(String.self, forKey: .viewClassName)
        viewId = try container.decodeIfPresent(String.self, forKey: .viewId)
        super.init(timestamp: timestamp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(eventType, forKey: .eventType)
        try container.encodeIfPresent(eventValue, forKey: .eventValue)
        try container.encodeIfPresent(eventValueKey, forKey: .eventValueKey)
        try container.encodeIfPresent(viewClassName, forKey: .viewClassName)
        try container.encodeIfPresent(viewId, forKey: .viewId)
    }

    public init(timestamp: Instana.Types.Milliseconds,
                eventType: String,
                eventValue: String? = nil,
                eventValueKey: String? = nil,
                viewClassName: String? = nil,
                viewId: String? = nil) {
        self.eventType = eventType
        self.eventValue = eventValue
        self.eventValueKey = eventValueKey
        self.viewClassName = viewClassName
        self.viewId = viewId
        super.init(timestamp: timestamp)
    }

    public var description: String {
        return """
        eventType:\(eventType), eventValue:\(eventValue ?? "nil"), eventValueKey:\(eventValueKey ?? "nil"),
        viewClassName:\(viewClassName ?? "nil"), viewId=\(viewId ?? "nil")
        """
    }
}
