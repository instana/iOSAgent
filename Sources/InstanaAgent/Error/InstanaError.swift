//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

/// Represents errors that can be thrown by the Instana SDK
enum InstanaError: LocalizedError, Equatable {
    static func == (lhs: InstanaError, rhs: InstanaError) -> Bool {
        lhs as NSError == rhs as NSError
    }

    case fileHandling(String)
    case invalidRequest
    case httpClientError(Int)
    case httpServerError(Int)
    case invalidResponse
    case missingAppKey
    case unknownType(String)
    case noWifiAvailable
    case offline
    case lowBattery
    case underlying(Error)

    var localizedDescription: String {
        switch self {
        case let .fileHandling(value):
            return "File handling failed \(value)"
        case .invalidRequest:
            return "Invalid URLRequest"
        case let .httpClientError(code):
            return "HTTP Client error occured code: \(code)"
        case let .httpServerError(code):
            return "HTTP Server  error occured code: \(code)"
        case .invalidResponse:
            return "Invalid response type"
        case .missingAppKey:
            return "Missing Instana app key"
        case let .unknownType(value):
            return "Type mismatch \(value)"
        case .noWifiAvailable:
            return "No WIFI Available"
        case .offline:
            return "No Internet connection available"
        case .lowBattery:
            return "Battery too low for flushing"
        case let .underlying(error):
            return "Underlying error \(error)"
        }
    }

    var errorDescription: String? {
        localizedDescription
    }

    var isHTTPClientError: Bool {
        switch self {
        case .httpClientError:
            return true
        default:
            return false
        }
    }

    var isUnknownType: Bool {
        switch self {
        case .unknownType:
            return true
        default:
            return false
        }
    }

    static func create(from error: Error) -> InstanaError {
        let nserror = error as NSError
        if nserror.code == NSURLErrorNotConnectedToInternet {
            return InstanaError.offline
        }
        return InstanaError.underlying(error)
    }
}

extension Optional where Wrapped == InstanaError {
    var isHTTPClientError: Bool {
        switch self {
        case let .some(value):
            return value.isHTTPClientError
        default:
            return false
        }
    }

    var isUnknownType: Bool {
        switch self {
        case let .some(value):
            return value.isUnknownType
        default:
            return false
        }
    }
}
