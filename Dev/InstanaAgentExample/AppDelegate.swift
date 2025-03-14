//
//  AppDelegate.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import UIKit
import InstanaAgent
import OSLog

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?   // needed on iOS 12 or lower

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let myLog = OSLog(subsystem: "com.instana.ios.InstanaAgentExample", category: "Instana")

        // App needs to explicitly get user consent for metric events subscription before catching crash payloads.
        let userYes = Instana.canSubscribeCrashReporting() &&
            (UserDefaults.standard.integer(forKey: metricSubscriptionKey) == metricSubscriptionFlagYes)

        let queryTrackedDomainList: [NSRegularExpression] = [
            try! NSRegularExpression(pattern: "https://www.ibm.com")
        ]

        let options = InstanaSetupOptions(enableCrashReporting: userYes)
//        options.slowSendInterval = 60.0
        options.autoCaptureScreenNames = true
//        options.debugAllScreenNames = true
        options.queryTrackedDomainList = queryTrackedDomainList
//        options.dropBeaconReporting = true
//        options.rateLimits = .MID_LIMITS
//        options.trustDeviceTiming = true
//        options.perfConfig = InstanaPerformanceConfig(enableAnrReport: true, anrThreshold: 5.0, enableLowMemoryReport: true)
        if !Instana.setup(key: InstanaKey, reportingURL: InstanaURL, options: options) {
            os_log("Instana setup failed", log: myLog, type: .error)
        }

        let headerFilterReg = try! NSRegularExpression(pattern: "Content-Type", options: .caseInsensitive)
        Instana.setCaptureHeaders(matching: [headerFilterReg])

        return true
    }

    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
