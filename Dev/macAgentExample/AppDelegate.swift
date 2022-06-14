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
        Instana.setup(key: InstanaKey, reportingURL: InstanaURL, httpCaptureConfig: .automatic)

        let url = URL(string: "https://www.instana.com")!
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { _, _, _ in
        }.resume()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
