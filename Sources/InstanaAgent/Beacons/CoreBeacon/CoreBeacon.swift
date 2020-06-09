import Foundation

enum BeaconType: String, Equatable, Codable, CustomStringConvertible {
    case sessionStart
    case httpRequest
    case viewChange
    case custom
    case crash
    case alert
    var description: String { rawValue }
}

// swiftlint:disable identifier_name

/// The final object that is used for the submission to the Instana backend
/// This model uses a short field name to reduce the transfer size
/// We transfer a simple String (no json) to the backend via the HTTP body.
/// That means we also loose the type information, so we need treat all fields as String
struct CoreBeacon: Equatable, Codable {
    /**
     * The max byte for each field (bytes)
     *
     *
     * Default: To be discussed if it can be dynamic
     */
    static let maxBytesPerField: Instana.Types.Bytes = 10000

    /**
     * The type of the beacon.
     *
     * For example: `sessionStart`
     *
     * Default: undefined
     */
    var t: BeaconType?

    /**
     * View
     *
     * The current visible view name
     *
     * For example: `WebView: Privacy Policy`
     *
     */
    var v: String?

    /**
     * Backend Tracing ID
     *
     * The backend exposes trace IDs via the Server-Timing HTTP response header.
     * The app needs to pick up the trace ID from this header and put it into this field.
     *
     * For example: Server-Timing: intid;desc=bd777df70e5e5356
     *
     * Note: In this case the field should hold the value bd777df70e5e5356.
     * This allows us to build a connection between end-user (mobile monitoring) and backend activity (tracing).
     */
    var bt: String?

    /**
     * App Key
     *
     * This key is the ID under which data can be reported to Instana. This ID will be created when creating a mobile app via the UI.
     * Provided by the mobile app configuration endpoint from Groundskeeper similar to how it is done for websites.
     */
    var k: String

    /**
     * Timestamp
     *
     * The timestamp in ms when the beacon has been created
     */
    var ti: String

    /**
     * Session ID
     *
     * The Session ID (UUID) will be created after each app after each app launch.
     * Each Session ID has a timeout of XY seconds.
     * The Session ID must not be empty.
     */
    var sid: String

    /**
     * Beacon ID
     *
     * An unique UUID for each beaon.
     * The app needs to set the Beacon ID when creating a beacon.
     */
    var bid: String

    /**
     * Bundle ID
     *
     * The unique bundle identifier for the app.
     *
     * For example: com.instana.ios.app
     */
    var bi: String

    /**
     * Custom Event name
     *
     * Defines what kind of event has happened in your app that should result in the transmission of a custom beacon.
     */
    var cen: String?

    /**
     * Meta for custom key/value entries
     *
     * Will be converted at transmission to separated string prefixed by `m_`
     * For example: `m_email    some@example.com`
     *
     * optional
     */
    var m: [String: String]?

    /**
     * User ID
     *
     * An identifier for the user.
     *
     * optional
     */
    var ui: String?

    /**
     * User name.
     *
     * optional
     */
    var un: String?

    /**
     * User’s email address.
     *
     * optional
     */
    var ue: String?

    /**
     * Current selected language for the app
     * The language is described using BCP 47 language tags.
     *
     * For example: en-US
     *
     * optional
     */
    var ul: String?

    /**
     * Build version
     *
     * Build version specifies build number of the bundle, which identifies an iteration (released or unreleased) of the bundle
     * The build version is unique for each app version and should be incremented on each deployed build.
     *
     *  For example: 1203A
     */
    var ab: String

    /**
     * App version
     *
     * AppVersion specifies the version for each store release. The AppVersion should conform to the semantic versioning.
     *
     * For example: 1.3.1
     */
    var av: String

    /**
     * Name of the platform (same as osn)
     *
     * For example: iOS or tvOS
     */
    var p: String

    /**
     * Name of the OS
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
     * Device manufacturer
     *
     * For example: Apple
     */
    var dma: String = "Apple"

    /**
     * Device model
     *
     * For example: iPhone12,5  (iPhone 11 Pro Max)
     */
    var dmo: String

    /**
     * Instana Agent version
     *
     * For example: 1.0.3
     */
    var agv: String

    /**
     * Whether the mobile device is rooted / jailbroken. True indicates that the device is definitely rooted / jailbroken.
     * False indicates that it isn't or that we could not identify the correct it.
     */
    var ro: String?

    /**
     * Device screen width in pixels
     *
     * For example: 2436
     */
    var vw: String

    /**
     * Device screen height in pixels
     *
     * For example: 1125
     */
    var vh: String

    /**
     * Cellular carrier name
     *
     * For example: Deutsche Telekom, Sprint, Verizon
     */
    var cn: String?

    /**
     * Connection type
     *
     * For example: Wifi, 4G, 3G or Edge
     */
    var ct: String?

    /**
     * Full URL for HTTP calls of all kinds.
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
     * Http method.
     *
     * For example: POST
     */
    var hm: String?

    /**
     * HTTP status code
     *
     * Zero means that the value wasn't recorded.
     *
     * For example: 404
     */
    var hs: String?

    /**
     * Size of the encoded
     *
     * (e.g. zipped) HTTP response body. Does not include the size of headers. Can be equal to decodedBodySize
     * when the response is not compressed.
     */
    var ebs: String?

    /**
     * Size of the decoded
     *
     * (e.g. unzipped) HTTP response body. Does not include the size of headers. Can be equal to {@link #encodedBodySize}
     * when the response is not compressed.
     */
    var dbs: String?

    /**
     * Total size of the HTTP response
     *
     * including response headers and the encoded response body.
     */
    var trs: String?

    /**
     * Duration in milliseconds
     *
     * In case of instantaneous events, use 0.
     */
    var d: String?

    /**
     * Error count
     */
    var ec: String?

    /**
     * ErrorMessage
     *
     * An arbitrary error message sent by the app.
     *
     * For example: "Error: Could not start a payment request."
     */
    var em: String?

    /**
     * ErrorType
     *
     * Type of the error
     *
     * For example: "Timeout"
     */
    var et: String?
}
