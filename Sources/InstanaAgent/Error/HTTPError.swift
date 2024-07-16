//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

enum HTTPError: LocalizedError, RawRepresentable, CustomStringConvertible, Equatable {
    case offline
    case timeout
    case cancelled
    case badURL
    case callIsActive
    case cannotConnectToHost
    case cannotDecodeContentData
    case cannotDecodeRawData
    case cannotLoadFromNetwork
    case cannotCreateFile
    case noPermissionsToReadFile
    case cannotMoveFile
    case cannotOpenFile
    case cannotRemoveFile
    case cannotWriteToFile
    case dataLengthExceedsMaximum
    case dataNotAllowed
    case dnsLookupFailed
    case downloadDecodingFailedMidStream
    case downloadDecodingFailedToComplete
    case tooManyRedirects
    case redirectToNonExistentLocation
    case internationalRoamingOff
    case networkConnectionLost

    case certificateRejected
    case certificateRequired
    case secureConnectionFailed
    case serverCertificateHasBadDate
    case serverCertificateHasUnknownRoot
    case serverCertificateNotYetValid
    case serverCertificateUntrusted
    case atsRequiresSecureConnection

    case unsupportedURL
    case userAuthenticationRequired
    case userCancelledAuthentication

    case statusCode(Int, NSError?)
    case unknownHTTPError(NSError)
    case unknown(NSError)

    var rawValue: String {
        switch self {
        case .offline: return "Offline"
        case .timeout: return "Timeout"
        case .cancelled: return "Cancelled"
        case .badURL: return "Bad URL"
        case .callIsActive: return "Call Is Active"
        case .cannotConnectToHost: return "Cannot Connect To Host"
        case .cannotDecodeContentData: return "Cannot Decode ContentData"
        case .cannotDecodeRawData: return "Cannot Decode RawData"
        case .cannotLoadFromNetwork: return "Cannot Load From Network"
        case .cannotCreateFile: return "Cannot Create File"
        case .noPermissionsToReadFile: return "No Permissions To Read File"
        case .cannotMoveFile: return "Cannot Move File"
        case .cannotOpenFile: return "Cannot Open File"
        case .cannotRemoveFile: return "Cannot Remove File"
        case .cannotWriteToFile: return "Cannot Write To File"
        case .dataLengthExceedsMaximum: return "Data Length Exceeds Maximum"
        case .dataNotAllowed: return "Data Not Allowed"
        case .dnsLookupFailed: return "DNS Lookup Failed"
        case .downloadDecodingFailedMidStream: return "Download Decoding Failed MidStream"
        case .downloadDecodingFailedToComplete: return "Download Decoding Failed To Complete"
        case .tooManyRedirects: return "Too Many Redirects"
        case .redirectToNonExistentLocation: return "Redirect To Non Existent Location"
        case .internationalRoamingOff: return "International Roaming Off"
        case .networkConnectionLost: return "Network Connection Lost"
        case .certificateRejected: return "Certificate Rejected"
        case .certificateRequired: return "Certificate Required"
        case .secureConnectionFailed: return "Secure Connection Failed"
        case .serverCertificateHasBadDate: return "Server Certificate Has Bad Date"
        case .serverCertificateHasUnknownRoot: return "Server Certificate Has Unknown Root"
        case .serverCertificateNotYetValid: return "Server Certificate Not Yet Valid"
        case .serverCertificateUntrusted: return "Server Certificate Untrusted"
        case .atsRequiresSecureConnection: return "ATS Requires SSL"
        case .unsupportedURL: return "Unsupported URL"
        case .userAuthenticationRequired: return "User Authentication Required"
        case .userCancelledAuthentication: return "User Cancelled Authentication"
        case let .statusCode(code, _): return "HTTP \(code)"
        case .unknownHTTPError: return "URL Error"
        case .unknown: return "Error"
        }
    }

    var description: String {
        errorDescription
    }

    var localizedDescription: String {
        errorDescription
    }

    var errorDescription: String {
        switch self {
        case .offline: return "A network resource was requested, but an internet connection has not been established and can’t be established automatically."
        case .timeout: return "An asynchronous operation timed out."
        case .cancelled: return "An asynchronous load has been canceled."
        case .badURL: return "A malformed URL prevented a URL request from being initiated."
        case .callIsActive: return "A connection was attempted while a phone call was active on a network that doesn’t support simultaneous phone and data communication, such as EDGE or GPRS."
        case .cannotConnectToHost: return "An attempt to connect to a host failed."
        case .cannotDecodeContentData: return "Content data received during a connection request had an unknown content encoding."
        case .cannotDecodeRawData: return "Content data received during a connection request couldn’t be decoded for a known content encoding."
        case .cannotLoadFromNetwork: return "A specific request to load an item only from the cache couldn't be satisfied."
        case .cannotCreateFile: return "A download task couldn’t create the downloaded file on disk because of an I/O failure."
        case .noPermissionsToReadFile: return "A resource couldn’t be read because of insufficient permissions."
        case .cannotMoveFile: return "A downloaded file on disk couldn’t be moved."
        case .cannotOpenFile: return "A downloaded file on disk couldn’t be opened."
        case .cannotRemoveFile: return "A downloaded file couldn’t be removed from disk."
        case .cannotWriteToFile: return "A download task couldn’t write the file to disk."
        case .dataLengthExceedsMaximum: return "The length of the resource data exceeded the maximum allowed."
        case .dataNotAllowed: return "The cellular network disallowed a connection."
        case .dnsLookupFailed: return "The host address couldn’t be found via DNS lookup."
        case .downloadDecodingFailedMidStream: return "A download task failed to decode an encoded file during the download."
        case .downloadDecodingFailedToComplete: return "A download task failed to decode an encoded file after downloading."
        case .tooManyRedirects: return "A redirect loop was detected or the threshold for number of allowable redirects was exceeded (currently 16)."
        case .redirectToNonExistentLocation: return "A redirect was specified by way of server response code, but the server didn’t accompany this code with a redirect URL."
        case .internationalRoamingOff: return "The attempted connection required activating a data context while roaming, but international roaming is disabled."
        case .networkConnectionLost: return "A client or server connection was severed in the middle of an in-progress load."
        case .certificateRejected: return "A server certificate was rejected."
        case .certificateRequired: return "A client certificate was required to authenticate an SSL connection during a connection request."
        case .secureConnectionFailed: return "An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically."
        case .serverCertificateHasBadDate: return "A server certificate is expired, or is not yet valid."
        case .serverCertificateHasUnknownRoot: return "A server certificate wasn’t signed by any root server."
        case .serverCertificateNotYetValid: return "A server certificate isn’t valid yet."
        case .serverCertificateUntrusted: return "A server certificate was signed by a root server that isn’t trusted."
        case .atsRequiresSecureConnection: return "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection."
        case .unsupportedURL: return "A properly formed URL couldn’t be handled by the framework."
        case .userAuthenticationRequired: return "Authentication was required to access a resource."
        case .userCancelledAuthentication: return "An asynchronous request for authentication has been canceled by the user."

        case let .statusCode(code, nsError):
            guard let error = nsError else {
                return "HTTP Error with status code \(code)"
            }
            return error.localizedDescription

        case let .unknownHTTPError(error): return "\(error.localizedDescription)"
        case let .unknown(error): return "\(error.localizedDescription)"
        }
    }

    init?(rawValue: String) {
        debugAssertFailure("Wrong init - Use init?(error:, statusCode:)")
        return nil
    }

    // swiftlint:disable:next cyclomatic_complexity
    init?(error: NSError?, statusCode: Int? = nil) {
        if let httpCode = statusCode, 400 ... 599 ~= httpCode {
            self = .statusCode(httpCode, error)
            return
        }
        guard let error = error else {
            return nil
        }
        guard error.domain == NSURLErrorDomain else {
            self = .unknown(error)
            return
        }
        switch error.code {
        case NSURLErrorTimedOut: self = .timeout
        case NSURLErrorCancelled: self = .cancelled
        case NSURLErrorBadURL: self = .badURL
        case NSURLErrorCallIsActive: self = .callIsActive
        case NSURLErrorCannotConnectToHost: self = .cannotConnectToHost
        case NSURLErrorCannotDecodeContentData: self = .cannotDecodeContentData
        case NSURLErrorCannotDecodeRawData: self = .cannotDecodeRawData
        case NSURLErrorCannotLoadFromNetwork: self = .cannotLoadFromNetwork
        case NSURLErrorCannotCreateFile: self = .cannotCreateFile
        case NSURLErrorNoPermissionsToReadFile: self = .noPermissionsToReadFile
        case NSURLErrorCannotMoveFile: self = .cannotMoveFile
        case NSURLErrorCannotOpenFile: self = .cannotOpenFile
        case NSURLErrorCannotRemoveFile: self = .cannotRemoveFile
        case NSURLErrorCannotWriteToFile: self = .cannotWriteToFile
        case NSURLErrorDataLengthExceedsMaximum: self = .dataLengthExceedsMaximum
        case NSURLErrorDataNotAllowed: self = .dataNotAllowed
        case NSURLErrorDNSLookupFailed: self = .dnsLookupFailed
        case NSURLErrorDownloadDecodingFailedMidStream: self = .downloadDecodingFailedMidStream
        case NSURLErrorDownloadDecodingFailedToComplete: self = .downloadDecodingFailedToComplete
        case NSURLErrorHTTPTooManyRedirects: self = .tooManyRedirects
        case NSURLErrorRedirectToNonExistentLocation: self = .redirectToNonExistentLocation
        case NSURLErrorInternationalRoamingOff: self = .internationalRoamingOff
        case NSURLErrorNetworkConnectionLost: self = .networkConnectionLost
        case NSURLErrorNotConnectedToInternet: self = .offline
        case NSURLErrorSecureConnectionFailed: self = .secureConnectionFailed
        case NSURLErrorClientCertificateRejected: self = .certificateRejected
        case NSURLErrorClientCertificateRequired: self = .certificateRequired
        case NSURLErrorServerCertificateHasBadDate: self = .serverCertificateHasBadDate
        case NSURLErrorServerCertificateHasUnknownRoot: self = .serverCertificateHasUnknownRoot
        case NSURLErrorServerCertificateNotYetValid: self = .serverCertificateNotYetValid
        case NSURLErrorServerCertificateUntrusted: self = .serverCertificateUntrusted
        case NSURLErrorAppTransportSecurityRequiresSecureConnection: self = .atsRequiresSecureConnection
        case NSURLErrorUnsupportedURL: self = .unsupportedURL
        case NSURLErrorUserAuthenticationRequired: self = .userAuthenticationRequired
        case NSURLErrorUserCancelledAuthentication: self = .userCancelledAuthentication
        default: self = .unknownHTTPError(error)
        }
    }
}
