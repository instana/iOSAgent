//
//  ImageViewViewController.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import UIKit
import Combine
import InstanaAgent

class ImageViewViewController: UIViewController {

    lazy var imageView = UIImageView()
    lazy var session = { URLSession(configuration: URLSessionConfiguration.default) }()
    private var publisher: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(downloadImage)))

        downloadImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Instana.setView(name: "ImageView")
        Instana.reportEvent(name: "Custom Event", duration: 1001, backendTracingID: nil, error: NSError(domain: "Domain", code: 0, userInfo: nil), meta: ["Key": "Val"], viewName:"Image")
    }

    @objc func downloadImage() {
        let url = URL(string: "https://picsum.photos/900")!
        publisher = session.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .map { UIImage(data: $0.data) }
            .map(upload)
            .replaceError(with: UIImage())
            .assign(to: \.image, on: self.imageView)
    }

    func upload(_ image: UIImage?) -> UIImage? {
        let imgData = image?.jpegData(compressionQuality: 0.9)!
        let boundary = UUID().uuidString
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"userfile\"; filename=\"img.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpg\r\n\r\n".data(using: .utf8)!)
        data.append(imgData ?? Data())
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: "https://www.server.de/upload_with_redirect.php")!)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

        URLSession.shared.uploadTask(with: request, from: data) { (dataResult, response, error) in
            print(String(data: dataResult ?? Data(), encoding: .utf8) ?? "")
            print(error ?? "")
        }.resume()
        return image
    }
}

extension URLRequest {
    mutating func appendPOSTParameter(_ parameter: [String: String]) {
        if let jsonData: Data = try? JSONSerialization.data(withJSONObject: parameter, options: []) {
            self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
            self.httpBody = jsonData
        }
    }
}
