//
//  EventListViewController.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import UIKit
import Combine
import InstanaAgent

struct DataSource: Codable {
    struct Event: Codable {
        var name: String
        var image_url: String?
    }
    let results: [Event]
}

class EventListViewController: UITableViewController {

    private var publisher: AnyCancellable?
    lazy var session = { URLSession(configuration: URLSessionConfiguration.default) }()
    private var dataSource: DataSource?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadJSON()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Instana.setView(name: "EventList")
    }

    @objc func refresh() {
        loadJSON()
    }

    func loadJSON() {
        let url = URL(string: "https://api.mygigs.tapwork.de/eventsnearby?radius=80.0&latitude=52.52&longitude=13.410&apitoken=xQ3vdfKVIF")!
        publisher = session.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .map { $0.data }
            .decode(type: DataSource.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { _ in }, receiveValue: {[weak self] model in
                guard let self = self else { return }
                self.dataSource = model
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.results.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath)
        cell.textLabel?.text = dataSource?.results[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let event = dataSource?.results[indexPath.row] else { return }
        let detailViewController = DetailViewController(event: event)
        present(detailViewController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class DetailViewController: UIViewController {

    let label = UILabel()
    let imageView = UIImageView()
    let event: DataSource.Event
    private var publisher: AnyCancellable?

    init(event: DataSource.Event) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill

        imageView.addSubview(label)
        label.backgroundColor = UIColor.systemBackground
        label.text = event.name
        label.numberOfLines = 0
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            label.topAnchor.constraint(equalTo: imageView.topAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.trailingAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        loadImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Instana.setView(name: "EventDetail")
    }

    private func loadImage() {
        guard let url = URL(string: event.image_url ?? "") else {
            return
        }
        publisher = URLSession.shared.dataTaskPublisher(for: url)
        .receive(on: RunLoop.main)
        .map { UIImage(data: $0.data) }
        .sink(receiveCompletion: { _ in }, receiveValue: {[weak self] image in
            guard let self = self else { return }
            self.imageView.image = image
        })
    }
}
