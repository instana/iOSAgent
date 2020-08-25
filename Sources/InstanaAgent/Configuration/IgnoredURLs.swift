import Foundation

// Place all URLs or patterns here that should be ignored from being monitored in the automatic instrumentation

struct IgnoredURLs {
    static var excludedURLs: [URL] = []
    static var excludedPatterns: [String] = [
        ".*instabug.com.*",
    ]
}
