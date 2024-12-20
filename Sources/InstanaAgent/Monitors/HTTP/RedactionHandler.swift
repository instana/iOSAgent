import Foundation

class RedactionHandler {
    static var `default`: RedactionHandler {
        let keywords = ["password", "key", "secret"]
        let regex = keywords.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
        return RedactionHandler(regex: regex)
    }

    var regex = AtomicSet<NSRegularExpression>()
    var queryTrackedDomainList = AtomicArray<NSRegularExpression>()

    init(regex: [NSRegularExpression]) {
        self.regex = AtomicSet(regex)
    }

    func redact(url: URL) -> URL {
        guard var updatedQuery = url.query else {
            return url
        }
        // check if need to completely remove query part
        var urlInTrackedDomainList = false
        for domainRegExp in queryTrackedDomainList {
            let key = url.absoluteString
            let range = NSRange(location: 0, length: key.utf16.count)
            if !domainRegExp.matches(in: key, range: range).isEmpty {
                // current url matches with one of queryTrackedDomainList, keep all query params for the url.
                urlInTrackedDomainList = true
                break
            }
        }
        if !queryTrackedDomainList.isEmpty, !urlInTrackedDomainList {
            // queryTrackedDomainList is configured and not empty
            // but current url is not in the list,
            // then remove query part completely (thus no need to further redact)
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil // remove query part
            components?.fragment = nil
            return components?.url ?? url
        }

        // redact query to remove sensitive data
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

    func setQueryTrackedDomainList(regex: [NSRegularExpression]?) {
        queryTrackedDomainList = AtomicArray(regex ?? [])
    }
}
