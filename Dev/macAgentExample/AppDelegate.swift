//
//  AppDelegate.swift
//  macAgentExample
//
//  Created by Christian Menschel on 29.04.21.
//
import Cocoa
import InstanaAgent

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // todo: explicitly get user permission before set enableCrashReporting to true
        let options = InstanaSetupOptions(enableCrashReporting: true)
        _ = Instana.setup(key: InstanaKey, reportingURL: InstanaURL, options: options)

        let url = URL(string: "https://www.instana.com")!
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { _, _, _ in
        }.resume()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
