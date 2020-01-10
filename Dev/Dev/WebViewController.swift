import UIKit
import WebKit
import InstanaAgent
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
        loadLotsOfRequests()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isRunningTests {
            Instana.setView(name: "WebView: Instana.com")
        }
    }

    func loadLotsOfRequests() {
        (0...99).forEach {_ in
            let sessi = URLSession(configuration: URLSessionConfiguration.default)
            sessi.dataTask(with: URL(string: "https://www.spiegel.de")!) { (_, _, _) in
            }.resume()
        }
    }
}
