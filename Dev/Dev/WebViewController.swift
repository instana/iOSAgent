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
            Instana.setView(name: "WebView: Instana.com")
        }
    }
}
