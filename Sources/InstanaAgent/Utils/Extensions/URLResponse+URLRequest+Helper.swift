import Foundation

extension URLResponse {
    struct Pair {
        let key: String
        let value: String
    }

    var backendTracingID: String? {
        guard let httpResponse = self as? HTTPURLResponse,
            let servertiming = httpResponse.value(for: "Server-Timing")
        else { return nil }

        let items = servertiming.components(separatedBy: ", ")
        let pairs = items.map { item -> Pair? in
            let comps = item.components(separatedBy: "=")
            guard let key = comps.first, let value = comps.last else { return nil }
            return Pair(key: key, value: value)
        }
        let value = pairs.compactMap { $0 }.last(where: { $0.key == "intid;desc" })?.value ?? ""
        return !value.isEmpty ? value : nil
    }
}

extension HTTPURLResponse {
    func value(for field: String) -> String? {
        // HTTP headerfields are defined to be insensitive - but not in Swift's HTTPURLResponse.
        // Accessing HTTPURLResponse's headerfields is case-sensitive, which is wrong.
        // see: https://bugs.swift.org/browse/SR-2429
        // We could use: httpResponse.value(forHTTPHeaderField: "Server-Timing") - but this is only available since iOS 13
        // https://bugs.swift.org/browse/SR-2429?focusedCommentId=55490&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-55490
        if #available(iOS 13.0, *) {
            return value(forHTTPHeaderField: field)
        } else {
            guard let value = (allHeaderFields as NSDictionary)[field] as? String else { return nil }
            return value
        }
    }
}
