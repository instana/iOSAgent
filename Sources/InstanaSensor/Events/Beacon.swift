//
//  Beacon.swift
//  
//
//  Created by Christian Menschel on 26.11.19.
//

import Foundation

extension Beacon {

    static func create(from event: Event) -> Beacon {
        switch event {
        case let e as HTTPEvent:
            return http(e)
        case let e as AlertEvent:
            return alert(e)
        case let e as CustomEvent:
            return custom(e)
        case let e as SessionProfileEvent:
            return sessionProfile(e)
        default:
            assertionFailure("Event <-> Beacon mapping for event \(event) not defined")
            return Beacon.create(event)
        }
    }

    static func create(_ event: Event) -> Beacon {
        Beacon(maid: "Some", ti: event.timestamp, sid: event.sessionId, bid: event.eventId ?? UUID().uuidString, buid: InstanaSystemUtils.applicationBundleIdentifier, lg: Locale.current.languageCode ?? "na", ab: InstanaSystemUtils.applicationBuildNumber, av: InstanaSystemUtils.applicationVersion, osn: InstanaSystemUtils.systemName, osv: InstanaSystemUtils.systemVersion, dmo: InstanaSystemUtils.deviceModel, vw: Int(InstanaSystemUtils.screenSize.width), vh: Int(InstanaSystemUtils.screenSize.height), cn: InstanaSystemUtils.carrierName, ct: InstanaSystemUtils.connectionTypeDescription)
    }

    static func http(_ event: HTTPEvent) -> Beacon {
        var beacon = create(event)
        beacon.httpurl = event.url
        beacon.httpscode = event.responseCode
        beacon.httpm = event.method
        return beacon
    }

    static func alert(_ event: AlertEvent) -> Beacon {
        let beacon = create(event)
        return beacon
    }

    static func custom(_ event: CustomEvent) -> Beacon {
        let beacon = create(event)
        return beacon
    }

    static func sessionProfile(_ event: SessionProfileEvent) -> Beacon {
        let beacon = create(event)
        return beacon
    }
}

/// The final object that is used for the submission to the Instana backend
/// It uses short field name to reduce the transfer size
struct Beacon {

    /**
     * This is the ID under which data can be reported to Instana. This ID will be created when creating a mobile app via the UI.
     * Provided by the mobile app configuration endpoint from Groundskeeper similar to how it is done for websites.
     */
    var maid: String

    /**
     * The timestamp in ms when the beacon has been created
     */
    var ti: TimeInterval

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
    var httpurl: String?

    /**
     * The request's http method.
     *
     * For example: POST
     */
    var httpm: String?

    /**
     * HTTP status code
     * Zero means that the value wasn't recorded.
     *
     * For example: 404
     */
    var httpscode: Int?

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

