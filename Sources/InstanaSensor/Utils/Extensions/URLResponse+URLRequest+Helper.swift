import Foundation

extension URLResponse {
    var backendTracingID: String? {
        guard let httpResponse = self as? HTTPURLResponse,
            let servertiming = httpResponse.allHeaderFields["Server-Timing"] as? String,
            let regex = try? NSRegularExpression(pattern: "^intid;desc=(.+)$", options: .caseInsensitive),
            let match = regex.firstMatch(in: servertiming, options: [], range: NSRange(location: 0, length: servertiming.utf16.count)),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: servertiming)
            else { return nil }

        return String(servertiming[range])
    }
}

extension URLRequest {
    var bodyString: String? {
        guard let data = httpBody else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
