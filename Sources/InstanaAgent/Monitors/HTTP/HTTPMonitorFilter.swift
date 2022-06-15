import Foundation

class HTTPMonitorFilter {
    private let redactionHandler: RedactionHandler
    @Atomic var headerFieldsRegEx = [NSRegularExpression]()

    init(redactionHandler: RedactionHandler = .default) {
        self.redactionHandler = redactionHandler
    }

    func redact(url: URL) -> URL {
        redactionHandler.redact(url: url)
    }

    func setRedaction(regex: [NSRegularExpression]) {
        redactionHandler.regex = Set(regex)
    }

    func filterHeaderFields(_ header: HTTPHeader?) -> HTTPHeader? {
        guard let header = header else { return nil }
        var filtered = [String: String]()
        header.forEach { key, value in
            if shouldUseHeaderField(key: key) {
                filtered[key] = value
            }
        }
        return filtered
    }

    private func shouldUseHeaderField(key: String) -> Bool {
        for regex in headerFieldsRegEx {
            let range = NSRange(location: 0, length: key.utf16.count)
            if !regex.matches(in: key, range: range).isEmpty {
                return true
            }
        }
        return false
    }
}
