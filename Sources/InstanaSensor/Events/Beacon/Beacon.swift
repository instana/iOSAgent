//
//  Beacon.swift
//  
//
//  Created by Christian Menschel on 26.11.19.
//

import Foundation

extension Beacon {
    static func createDefault(_ event: Event, key: String) -> Beacon {
        Beacon(t: .custom, k: key, ti: event.timestamp, sid: event.sessionId, bid: event.eventId ?? UUID().uuidString, buid: InstanaSystemUtils.applicationBundleIdentifier, lg: Locale.current.languageCode ?? "na", ab: InstanaSystemUtils.applicationBuildNumber, av: InstanaSystemUtils.applicationVersion, osn: InstanaSystemUtils.systemName, osv: InstanaSystemUtils.systemVersion, dmo: InstanaSystemUtils.deviceModel, ro: InstanaSystemUtils.isDeviceJailbroken, vw: Int(InstanaSystemUtils.screenSize.width), vh: Int(InstanaSystemUtils.screenSize.height), cn: InstanaSystemUtils.carrierName, ct: InstanaSystemUtils.connectionTypeDescription)
    }

    mutating func append(_ event: HTTPEvent) {
        t = .httpRequest
        hu = event.url
        hp = event.path
        hs = event.responseCode
        hm = event.method
        trs = event.responseSize
        d = event.duration
    }

    mutating func append(_ event: AlertEvent) {
        t = .custom // not yet defined
    }

    mutating func append(_ event: CustomEvent) {
        t = .custom
    }

    mutating func append(_ event: SessionProfileEvent) {
        if event.state == .start {
            t = .sessionStart  // there is no such end yet
        }
    }
}

/// The final object that is used for the submission to the Instana backend
/// It uses short field name to reduce the transfer size
struct Beacon {

    enum `Type`: String {
        case sessionStart
        case httpRequest
        case crash
        case custom
    }

    /**
     * The type of the beacon.
     * Valid
     * For example: `sessionStart`
     */
    var t: Type

    /**
     * The backend exposes trace IDs via the Server-Timing HTTP response header.
     * The app needs to pick up the trace ID from this header and put it into this field.
     * For example: Server-Timing: intid;desc=bd777df70e5e5356
     * In this case the field should hold the value bd777df70e5e5356.
     * This allows us to build a connection between end-user (mobile monitoring) and backend activity (tracing).
     */
    var bt: String?


    /**
     * App Key
     * This key is the ID under which data can be reported to Instana. This ID will be created when creating a mobile app via the UI.
     * Provided by the mobile app configuration endpoint from Groundskeeper similar to how it is done for websites.
     */
    var k: String

    /**
     * The timestamp in ms when the beacon has been created
     */
    var ti: Int64

    /**
     *
     * Session ID (UUID) will be created after each app after each app launch.
     * Each Session ID has a timeout of XY seconds.
     * The Session ID must not be empty.
     */
    var sid: String

    /**
     * Beacon ID: An unique UUID for each beaon.
     * The app needs to set the Beacon ID when creating a beacon.
     */
    var bid: String

    /**
     * Bundle ID: The unique bundle identifier for the app.
     * For example: com.instana.ios.app
     */
    var buid: String

    /**
     * An identifier for the user.
     */
    var userId: String?

    /**
     * The user name. (optional)
     */
    var userName: String?

    /**
     * The user’s email address.
     */
    var ue: String?

    /**
     * The current selected language for the app
     * The language is described using BCP 47 language tags.
     *
     * For example: en-US"
     */
    var lg: String

    /**
     * Build version specifies build number of the bundle, which identifies an iteration (released or unreleased) of the bundle
     * The build version is unique for each app version and should be incremented on each deployed build.
     *
     *  For example: 1203A
     */
    var ab: String

    /**
     * AppVersion specifies the version for each store release. The AppVersion should conform to the semantic versioning.
     *
     * For example: 1.3.1
     */
    var av: String

    /**
     * The name of the OS platform
     *
     * For example: iOS or tvOS
     */
    var osn: String

    /**
     * The OS version of the platform without any information about OS name itself.
     *
     * For example: 12.0.1
     */
    var osv: String

    /**
     * The device manufacturer
     *
     * For example: Apple
     */
    var dmf: String = "Apple"

    /**
     * The device model
     *
     * For example: iPhone12,5  (iPhone 11 Pro Max)
     */
    var dmo: String

    /**
     * Whether the mobile device is rooted / jailbroken. True indicates that the device is definitely rooted / jailbroken.
     * False indicates that it isn't or that we could not identify the correct it.
     */
    var ro: Bool?

    /**
     * Device screen width in pixels
     *
     * For example: 2436
     */
    var vw: Int

    /**
     * Device screen height in pixels
     *
     * For example: 1125
     */
    var vh: Int

    /**
     * The cellular carrier name
     *
     * For example: Deutsche Telekom, Sprint, Verizon
     */
    var cn: String?

    /**
     * The connection type
     *
     * For example: Wifi, 4G, 3G or Edge
     */
    var ct: String?

    /**
     * The full URL for HTTP calls of all kinds.
     *
     * For example: https://stackoverflow.com/questions/4604486/how-do-i-move-an-existing-git-submodule-within-a-git-repository
     */
    var hu: String?

    /**
     * The path of the full URL
     *
     * For example: /questions/4604486/how-do-i-move-an-existing-git-submodule-within-a-git-repository
     *
     * Short serialization key: hp
     */
    var hp: String?

    /**
     * The request's http method.
     *
     * For example: POST
     */
    var hm: String?

    /**
     * HTTP status code
     * Zero means that the value wasn't recorded.
     *
     * For example: 404
     */
    var hs: Int?

    /**
     * The size of the encoded
     * (e.g. zipped) HTTP response body. Does not include the size of headers. Can be equal to decodedBodySize
     * when the response is not compressed.
     */
    var ebs: Int64?

    /**
     * The size of the decoded
     * (e.g. unzipped) HTTP response body. Does not include the size of headers. Can be equal to {@link #encodedBodySize}
     * when the response is not compressed.
     */
    var dbs: Int64?

    /**
     * The total size of the HTTP response
     * including response headers and the encoded response body.
     */
    var trs: Int64?

    /**
     * Duration in milliseconds
     * In case of instantaneous events, use 0.
     *
     */
    var d: Int64?

    /**
     * Error count
     */
    var ec: Int?

    /**
     * errorMessage
     *
     * An arbitrary error message sent by the app.
     *
     * For example: "Error: Could not start a payment request."
     */
    var em: String?

    /**
     * errorType
     *
     * Type of the error
     * For iOS: You could use the ErrorDomain or the Swift Error enum case
     *
     * For example: "NetworkError.timeout"
     */
    var et: String?
}

extension Beacon {

    var keyValuePairs: String {
        let mirror = Mirror(reflecting: self)
        let pairs = mirror.children.compactMap { kvPair($0) }
        return pairs.joined(separator: "\n")
    }

    // TODO: Test this
    func kvPair(_ node: Mirror.Child) -> String? {
        guard let key = node.label else { return nil }
        let mirror = Mirror(reflecting: node.value)
        if mirror.displayStyle == .optional {
            if let unwrapped = mirror.children.first?.value {
                return formattedKVPair(key: key, value: unwrapped)
            } else {
                return nil
            }
        } else {
            return formattedKVPair(key: key, value: node.value)
        }
    }

    func formattedKVPair(key: String, value: Any) -> String? {
        guard let value = cleaning(value) else { return nil }
        return "\(key)\t\(value)"
    }

    func cleaning<T: Any>(_ entry: T) -> T? {
        if let stringValue = entry as? String {
            var trimmed = stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            trimmed = trimmed.replacingOccurrences(of: "\t", with: "")
            return trimmed.isEmpty ? nil : trimmed as? T
        }
        return entry
    }
}
