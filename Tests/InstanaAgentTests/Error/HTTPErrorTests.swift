import Foundation
import XCTest
@testable import InstanaAgent

class HTTPErrorTests: XCTestCase {

    func test_offline() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorNotConnectedToInternet))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.offline)
        AssertEqualAndNotNil(sut?.description, "A network resource was requested, but an internet connection has not been established and can’t be established automatically.")
        AssertEqualAndNotNil(sut?.rawValue, "Offline")
    }

    func test_timeout() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorTimedOut))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.timeout)
        AssertEqualAndNotNil(sut?.description, "An asynchronous operation timed out.")
        AssertEqualAndNotNil(sut?.rawValue, "Timeout")
    }

    func test_cancelled() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCancelled))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cancelled)
        AssertEqualAndNotNil(sut?.description, "An asynchronous load has been canceled.")
        AssertEqualAndNotNil(sut?.rawValue, "Cancelled")
    }

    func test_badURL() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorBadURL))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.badURL)
        AssertEqualAndNotNil(sut?.description, "A malformed URL prevented a URL request from being initiated.")
        AssertEqualAndNotNil(sut?.rawValue, "Bad URL")
    }

    func test_callIsActive() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCallIsActive))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.callIsActive)
        AssertEqualAndNotNil(sut?.description, "A connection was attempted while a phone call was active on a network that doesn’t support simultaneous phone and data communication, such as EDGE or GPRS.")
        AssertEqualAndNotNil(sut?.rawValue, "Call Is Active")
    }

    func test_cannotConnectToHost() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotConnectToHost))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotConnectToHost)
        AssertEqualAndNotNil(sut?.description, "An attempt to connect to a host failed.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Connect To Host")
    }

    func test_cannotDecodeContentData() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotDecodeContentData))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotDecodeContentData)
        AssertEqualAndNotNil(sut?.description, "Content data received during a connection request had an unknown content encoding.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Decode ContentData")
    }

    func test_cannotDecodeRawData() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotDecodeRawData))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotDecodeRawData)
        AssertEqualAndNotNil(sut?.description, "Content data received during a connection request couldn’t be decoded for a known content encoding.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Decode RawData")
    }

    func test_cannotLoadFromNetwork() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotLoadFromNetwork))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotLoadFromNetwork)
        AssertEqualAndNotNil(sut?.description, "A specific request to load an item only from the cache couldn't be satisfied.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Load From Network")
    }

    func test_cannotCreateFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotCreateFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotCreateFile)
        AssertEqualAndNotNil(sut?.description, "A download task couldn’t create the downloaded file on disk because of an I/O failure.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Create File")
    }

    func test_noPermissionsToReadFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorNoPermissionsToReadFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.noPermissionsToReadFile)
        AssertEqualAndNotNil(sut?.description, "A resource couldn’t be read because of insufficient permissions.")
        AssertEqualAndNotNil(sut?.rawValue, "No Permissions To Read File")
    }

    func test_cannotMoveFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotMoveFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotMoveFile)
        AssertEqualAndNotNil(sut?.description, "A downloaded file on disk couldn’t be moved.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Move File")
    }

    func test_cannotOpenFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotOpenFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotOpenFile)
        AssertEqualAndNotNil(sut?.description, "A downloaded file on disk couldn’t be opened.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Open File")
    }

    func test_cannotRemoveFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotRemoveFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotRemoveFile)
        AssertEqualAndNotNil(sut?.description, "A downloaded file couldn’t be removed from disk.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Remove File")
    }

    func test_cannotWriteToFile() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorCannotWriteToFile))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.cannotWriteToFile)
        AssertEqualAndNotNil(sut?.description, "A download task couldn’t write the file to disk.")
        AssertEqualAndNotNil(sut?.rawValue, "Cannot Write To File")
    }

    func test_dataLengthExceedsMaximum() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorDataLengthExceedsMaximum))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.dataLengthExceedsMaximum)
        AssertEqualAndNotNil(sut?.description, "The length of the resource data exceeded the maximum allowed.")
        AssertEqualAndNotNil(sut?.rawValue, "Data Length Exceeds Maximum")
    }

    func test_dataNotAllowed() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorDataNotAllowed))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.dataNotAllowed)
        AssertEqualAndNotNil(sut?.description, "The cellular network disallowed a connection.")
        AssertEqualAndNotNil(sut?.rawValue, "Data Not Allowed")
    }

    func test_dnsLookupFailed() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorDNSLookupFailed))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.dnsLookupFailed)
        AssertEqualAndNotNil(sut?.description, "The host address couldn’t be found via DNS lookup.")
        AssertEqualAndNotNil(sut?.rawValue, "DNS Lookup Failed")
    }

    func test_downloadDecodingFailedMidStream() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorDownloadDecodingFailedMidStream))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.downloadDecodingFailedMidStream)
        AssertEqualAndNotNil(sut?.description, "A download task failed to decode an encoded file during the download.")
        AssertEqualAndNotNil(sut?.rawValue, "Download Decoding Failed MidStream")
    }

    func test_downloadDecodingFailedToComplete() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorDownloadDecodingFailedToComplete))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.downloadDecodingFailedToComplete)
        AssertEqualAndNotNil(sut?.description, "A download task failed to decode an encoded file after downloading.")
        AssertEqualAndNotNil(sut?.rawValue, "Download Decoding Failed To Complete")
    }

    func test_tooManyRedirects() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorHTTPTooManyRedirects))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.tooManyRedirects)
        AssertEqualAndNotNil(sut?.description, "A redirect loop was detected or the threshold for number of allowable redirects was exceeded (currently 16).")
        AssertEqualAndNotNil(sut?.rawValue, "Too Many Redirects")
    }

    func test_redirectToNonExistentLocation() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorRedirectToNonExistentLocation))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.redirectToNonExistentLocation)
        AssertEqualAndNotNil(sut?.description, "A redirect was specified by way of server response code, but the server didn’t accompany this code with a redirect URL.")
        AssertEqualAndNotNil(sut?.rawValue, "Redirect To Non Existent Location")
    }

    func test_internationalRoamingOff() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorInternationalRoamingOff))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.internationalRoamingOff)
        AssertEqualAndNotNil(sut?.description, "The attempted connection required activating a data context while roaming, but international roaming is disabled.")
        AssertEqualAndNotNil(sut?.rawValue, "International Roaming Off")
    }

    func test_networkConnectionLost() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorNetworkConnectionLost))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.networkConnectionLost)
        AssertEqualAndNotNil(sut?.description, "A client or server connection was severed in the middle of an in-progress load.")
        AssertEqualAndNotNil(sut?.rawValue, "Network Connection Lost")
    }

    func test_certificateRejected() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorClientCertificateRejected))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.certificateRejected)
        AssertEqualAndNotNil(sut?.description, "A server certificate was rejected.")
        AssertEqualAndNotNil(sut?.rawValue, "Certificate Rejected")
    }

    func test_certificateRequired() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorClientCertificateRequired))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.certificateRequired)
        AssertEqualAndNotNil(sut?.description, "A client certificate was required to authenticate an SSL connection during a connection request.")
        AssertEqualAndNotNil(sut?.rawValue, "Certificate Required")
    }

    func test_secureConnectionFailed() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorSecureConnectionFailed))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.secureConnectionFailed)
        AssertEqualAndNotNil(sut?.description, "An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically.")
        AssertEqualAndNotNil(sut?.rawValue, "Secure Connection Failed")
    }

    func test_serverCertificateHasBadDate() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorServerCertificateHasBadDate))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.serverCertificateHasBadDate)
        AssertEqualAndNotNil(sut?.description, "A server certificate is expired, or is not yet valid.")
        AssertEqualAndNotNil(sut?.rawValue, "Server Certificate Has Bad Date")
    }

    func test_serverCertificateHasUnknownRoot() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorServerCertificateHasUnknownRoot))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.serverCertificateHasUnknownRoot)
        AssertEqualAndNotNil(sut?.description, "A server certificate wasn’t signed by any root server.")
        AssertEqualAndNotNil(sut?.rawValue, "Server Certificate Has Unknown Root")
    }

    func test_serverCertificateNotYetValid() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorServerCertificateNotYetValid))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.serverCertificateNotYetValid)
        AssertEqualAndNotNil(sut?.description, "A server certificate isn’t valid yet.")
        AssertEqualAndNotNil(sut?.rawValue, "Server Certificate Not Yet Valid")
    }

    func test_serverCertificateUntrusted() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorServerCertificateUntrusted))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.serverCertificateUntrusted)
        AssertEqualAndNotNil(sut?.description, "A server certificate was signed by a root server that isn’t trusted.")
        AssertEqualAndNotNil(sut?.rawValue, "Server Certificate Untrusted")
    }

    func test_appTransportSecurityRequiresSecureConnection() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorAppTransportSecurityRequiresSecureConnection))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.atsRequiresSecureConnection)
        AssertEqualAndNotNil(sut?.description, "The resource could not be loaded because the App Transport Security policy requires the use of a secure connection.")
        AssertEqualAndNotNil(sut?.rawValue, "ATS Requires SSL")
    }

    func test_unsupportedURL() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorUnsupportedURL))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.unsupportedURL)
        AssertEqualAndNotNil(sut?.description, "A properly formed URL couldn’t be handled by the framework.")
        AssertEqualAndNotNil(sut?.rawValue, "Unsupported URL")
    }

    func test_userAuthenticationRequired() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorUserAuthenticationRequired))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.userAuthenticationRequired)
        AssertEqualAndNotNil(sut?.description, "Authentication was required to access a resource.")
        AssertEqualAndNotNil(sut?.rawValue, "User Authentication Required")
    }

    func test_userCancelledAuthentication() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorUserCancelledAuthentication))

        // Then
        AssertEqualAndNotNil(sut, HTTPError.userCancelledAuthentication)
        AssertEqualAndNotNil(sut?.description, "An asynchronous request for authentication has been canceled by the user.")
        AssertEqualAndNotNil(sut?.rawValue, "User Cancelled Authentication")
    }

    func test_statusCode() {
        // Given
        let sut = HTTPError(error: nil, statusCode: 404)

        // Then
        AssertEqualAndNotNil(sut, HTTPError.statusCode(404))
        AssertEqualAndNotNil(sut?.description, "HTTP Error with status code 404")
        AssertEqualAndNotNil(sut?.rawValue, "HTTP 404")
    }

    func test_statusCode_overriding_error() {
        // Given
        let sut = HTTPError(error: error(NSURLErrorTimedOut), statusCode: 404)

        // Then
        AssertEqualAndNotNil(sut, HTTPError.statusCode(404))
        AssertEqualAndNotNil(sut?.description, "HTTP Error with status code 404")
        AssertEqualAndNotNil(sut?.rawValue, "HTTP 404")
    }

    func test_unknownHTTPError() {
        // Given
        let theError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBackgroundSessionRequiresSharedContainer, userInfo: nil)
        let sut = HTTPError(error: theError)

        // Then
        AssertEqualAndNotNil(sut, HTTPError.unknownHTTPError(theError))
        AssertEqualAndNotNil(sut?.description, "URL Error: \(theError.localizedDescription)")
        AssertEqualAndNotNil(sut?.rawValue, "Some URL Error")
    }

    func test_unknownError() {
        // Given
        let error = NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil)
        let sut = HTTPError(error: error)

        // Then
        AssertEqualAndNotNil(sut, HTTPError.unknown(error))
        AssertEqualAndNotNil(sut?.description, "Underlying Error \(error.localizedDescription)")
        AssertEqualAndNotNil(sut?.rawValue, "Some underlying Error")
    }

    // MARK: Helper
    func error(_ code: Int) -> NSError {
        NSError(domain: NSURLErrorDomain, code: code, userInfo: nil)
    }
}
