import Foundation

struct IgnoreURLHandler {
    /// Monitor ignores URLs that match the given regular expressions
    static var regexPatterns = [String]()

    /// Monitor ignores the exact URLs given in this collection
    static var exactURLs = [URL]()

    static func shouldIgnore(_ url: URL) -> Bool {
        if exactURLs.contains(url) {
            return true
        }
        let matches = regexPatterns.flatMap { url.matches(regex: $0) }
        return matches.count > 0
    }
}

extension URL {
    func matches(regex: String) -> [String] {
        do {
            let text = absoluteString
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map { String(text[Range($0.range, in: text)!]) }
        } catch {
            return []
        }
    }
}
