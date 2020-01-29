//
//  ImageViewViewController.swift
//  iOSAgentExample
//
//  Created by Christian Menschel on 22.11.19.
//  Copyright © 2019 Instana Inc. All rights reserved.
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
    }

    @objc func downloadImage() {
        let url = URL(string: "https://picsum.photos/900")!
        publisher = session.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .assertNoFailure()
            .map { UIImage(data: $0.data)}
            .assign(to: \.image, on: self.imageView)
    }
}

extension URLRequest {
    mutating func appendPOSTParameter(_ parameter: [String: String]) {
        if let jsonData: Data = try? JSONSerialization.data(withJSONObject: parameter, options: []) {
            self.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
            self.httpBody = jsonData
        } else {
            debugAssertFailure("Could not serialize JSON")
        }
    }
}
