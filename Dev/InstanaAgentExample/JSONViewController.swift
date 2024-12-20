//
//  JSONViewController.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import UIKit
import Combine
import InstanaAgent

@available(iOS 13.0, *)
class JSONViewController: UIViewController {

    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var textView: UITextView!

    @available(iOS 13.0, *)
    private var publisher: AnyCancellable?

    lazy var session = { URLSession(configuration: URLSessionConfiguration.default) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.accessibilityLabel = "JSONView Accessibility Label 1"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        Instana.setView(name: "JSONView")
        searchTextField.text = "https://www.ibm.com/de-de?abc=123&password=ps"
    }

    @IBAction func loadJSON() {
        searchTextField.resignFirstResponder()
        guard let url = URL(string: searchTextField.text ?? "") else {
            showAlert(message: "URL is invalid")
            return
        }
        if #available(iOS 13.0, *) {
            publisher = session.dataTaskPublisher(for: url)
                .receive(on: RunLoop.main)
                .map { String(data: $0.data, encoding: .ascii) }
                .sink(receiveCompletion: { complete in
                    if let errorMessage = complete.localizedError {
                        self.showAlert(message: errorMessage)
                    }
                }, receiveValue: {[weak self] result in
                    self?.textView.text = result
                })
        } else {
            let task = session.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    print("Empty data. error: ", error ?? "nil")
                    return
                }
                let str = String(data: data, encoding: .utf8)
                DispatchQueue.main.async {
                    self.textView.text = str
                }
            }
            task.resume()
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

@available(iOS 13.0, *)
extension JSONViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loadJSON()
        return true
    }
}

@available(iOS 13.0, *)
extension Subscribers.Completion {
    var error: Error? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }

    var localizedError: String? {
        error?.localizedDescription
    }

    var hasError: Bool { error != nil }
}
