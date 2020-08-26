import Foundation

struct IgnoreURLHandler {
    /// Monitor ignores URLs that match the given regular expressions
    static var regex = Set<NSRegularExpression>()

    /// Monitor ignores the exact URLs given in this collection
    static var exactURLs = Set<URL>()

    /// All sessions will be ignored from HTTP monitoring
    static var urlSessions = Set<URLSession>()

    static func shouldIgnore(_ url: URL) -> Bool {
        if exactURLs.contains(url) {
            return true
        }
        let matches = regex.flatMap { url.matches(regex: $0) }
        return matches.count > 0
    }

    static func ignore(pattern: String) {
        if let regular = try? NSRegularExpression(pattern: pattern) {
            regex.insert(regular)
        }
    }

    static func ignore(patterns: [String]) {
        patterns.forEach { ignore(pattern: $0) }
    }

    static func loadDefaultIgnoredURLs(session: InstanaSession? = nil) {
        if let session = session {
            exactURLs.insert(session.configuration.reportingURL)
        }
        exactURLs.formUnion(IgnoredURLs.excludedURLs)
        ignore(patterns: IgnoredURLs.excludedPatterns)
    }
}

extension URL {
    func matches(regex: NSRegularExpression) -> [String] {
        let text = absoluteString
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map { String(text[Range($0.range, in: text)!]) }
    }
}
