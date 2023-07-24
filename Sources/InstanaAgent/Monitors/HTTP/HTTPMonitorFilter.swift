import Foundation

class HTTPMonitorFilter {
    private let redactionHandler: RedactionHandler
    var headerFieldsRegEx = AtomicArray<NSRegularExpression>()

    init(redactionHandler: RedactionHandler = .default) {
        self.redactionHandler = redactionHandler
    }

    func redact(url: URL) -> URL {
        redactionHandler.redact(url: url)
    }

    func setRedaction(regex: [NSRegularExpression]) {
        redactionHandler.regex = AtomicSet(regex)
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

    func needHeaderFields() -> Bool {
        return !headerFieldsRegEx.isEmpty
    }

    func shouldUseHeaderField(key: String) -> Bool {
        for regex in headerFieldsRegEx {
            let range = NSRange(location: 0, length: key.utf16.count)
            if !regex.matches(in: key, range: range).isEmpty {
                return true
            }
        }
        return false
    }
}
