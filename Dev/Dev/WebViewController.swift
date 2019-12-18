//
//  WebViewController.swift
//  iOSSensor-Development
//
//  Created by Christian Menschel on 10.12.19.
//  Copyright © 2019 Instana Inc. All rights reserved.
//

import UIKit
import WebKit
import InstanaSensor
import Combine

class WebViewController: UIViewController {


    lazy var webView: WKWebView = {
        let conf = WKWebViewConfiguration()
        let webview = WKWebView(frame: .zero, configuration: conf)
        return webview
    }()

    override func loadView() {
        view = webView
        webView.load(URLRequest(url: URL(string: "https://www.instana.com")!))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isRunningTests {
            Instana.propertyHandler.setVisibleView(name: "WebView: Instana.com")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isRunningTests {
            Instana.propertyHandler.unsetVisibleView()
        }
    }
}
