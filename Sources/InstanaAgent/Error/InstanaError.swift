import Foundation

/// Represents errors that can be thrown by the Instana SDK
class InstanaError: NSError {
    static let domain = "com.instana.ios.agent.error"

    enum Code: Int {
        case invalidRequest
        case invalidResponse
        case notAuthenticated
        case bufferOverwrite
        case unknownType
        case noWifiAvailable
        case offline
        case lowBattery
    }

    init(code: Code, description: String) {
        super.init(domain: InstanaError.domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
