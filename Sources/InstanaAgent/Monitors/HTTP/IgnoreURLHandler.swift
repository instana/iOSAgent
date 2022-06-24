//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

struct IgnoreURLHandler {
    /// Monitor ignores URLs that match the given regular expressions
    static var regex = AtomicSet<NSRegularExpression>()

    /// Monitor ignores the exact URLs given in this collection
    static var exactURLs = AtomicSet<URL>()

    /// All sessions will be ignored from HTTP monitoring
    static var urlSessions = AtomicSet<URLSession>()

    static func ignore(session: URLSession) {
        urlSessions.insert(session)
    }

    static func shouldIgnore(_ session: URLSession) -> Bool {
        urlSessions.contains(session)
    }

    static func ignore(regularExpressions: [NSRegularExpression]) {
        regex.formUnion(Set(regularExpressions))
    }

    static func ignore(urls: [URL]) {
        exactURLs.formUnion(Set(urls))
    }

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

    static func loadDefaultDefaultIgnoredURLs(session: InstanaSession? = nil) {
        if let session = session {
            exactURLs.insert(session.configuration.reportingURL)
        }
        exactURLs.formUnion(DefaultIgnoredURLs.excludedURLs)
        ignore(patterns: DefaultIgnoredURLs.excludedPatterns)
    }
}

extension URL {
    func matches(regex: NSRegularExpression) -> [String] {
        let text = absoluteString
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.map { String(text[Range($0.range, in: text)!]) }
    }
}
