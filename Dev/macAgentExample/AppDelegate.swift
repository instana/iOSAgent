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
        Instana.setup(key: InstanaKey, reportingURL: URL(string: InstanaURL)!)

        URLSession.shared.dataTask(with: URL(string: "https://www.instana.com")!).resume()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

