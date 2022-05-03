import Foundation
import SwiftUI

class RedactionHandler {
    static var `default`: RedactionHandler {
        let keywords = ["password", "key", "secret"]
        let regex = keywords.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
        return RedactionHandler(regex: regex)
    }

    @Atomic var regex = Set<NSRegularExpression>()

    init(regex: [NSRegularExpression]) {
        self.regex = Set(regex)
    }

    func redact(url: URL) -> URL {
        guard var updatedQuery = url.query else {
            return url
        }
        regex.forEach {
            updatedQuery = redact(query: updatedQuery, matching: $0)
        }
        var urlComp = URLComponents(url: url, resolvingAgainstBaseURL: true)
        urlComp?.query = updatedQuery
        return urlComp?.url ?? url
    }

    private func redact(query: String, matching regex: NSRegularExpression) -> String {
        let queryItems = query.components(separatedBy: "&")
        return queryItems.compactMap { item -> String in
            guard let key = item.components(separatedBy: "=").first else {
                return item
            }
            let range = NSRange(location: 0, length: key.utf16.count)
            guard !regex.matches(in: key, range: range).isEmpty else {
                return item
            }
            return "\(key)=<redacted>"
        }.joined(separator: "&")
    }
}
