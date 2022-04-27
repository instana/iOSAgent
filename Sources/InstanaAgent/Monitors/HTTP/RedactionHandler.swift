import Foundation
import SwiftUI

class RedactionHandler {

    static var `default`: RedactionHandler {
        let keywords = ["password", "key", "secret"]
        let regex = keywords.compactMap {
            try? NSRegularExpression(pattern: #"(?<="# + $0 + #"=)[^&]+"#, options: [.caseInsensitive])
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
            updatedQuery = redact(path: updatedQuery, matching: $0)
        }
        var urlComp = URLComponents(url: url, resolvingAgainstBaseURL: true)
        urlComp?.query = updatedQuery
        return urlComp?.url ?? url
    }

    private func redact(path: String, matching regex: NSRegularExpression) -> String {
        let range = NSRange(location: 0, length: path.utf16.count)
        let substitution = #"$1redacted"#
        return regex.stringByReplacingMatches(in: path, range: range, withTemplate: substitution)
    }
}
