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

var selectedContent: [String] = []

var dataSource: DataSource?

@available(iOS 13.0, *)
class EventListViewController: UITableViewController {
    
    class RateButtonCell: UITableViewCell {
        let rateButton = UIButton(type: .system)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            if #available(iOS 13.0, *) {
                rateButton.setImage(UIImage(systemName: "star"), for: .normal)
                rateButton.setImage(UIImage(systemName: "star.fill"), for: .selected)
            }
            accessoryView = rateButton
        }
        
        
        override func layoutSubviews() {
            super.layoutSubviews()
            rateButton.frame = CGRect(x: contentView.bounds.width - 60, y: 10, width: 60, height: contentView.bounds.height - 20)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    


    @available(iOS 13.0, *)
    private var publisher: AnyCancellable?

    lazy var session = { URLSession(configuration: URLSessionConfiguration.default) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadJSON()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
        tableView.register(RateButtonCell.self, forCellReuseIdentifier: "CELL")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        Instana.setView(name: "EventList")
    }

    @objc func refresh() {
        loadJSON()
    }

    func loadJSON() {
        let url = URL(string: "https://api.mygigs.tapwork.de/eventsnearby?radius=80.0&latitude=52.52&longitude=13.410&apitoken=xQ3vdfKVIF")!
        if #available(iOS 13.0, *) {
            publisher = session.dataTaskPublisher(for: url)
                .receive(on: RunLoop.main)
                .map { $0.data }
                .decode(type: DataSource.self, decoder: JSONDecoder())
                .sink(receiveCompletion: { _ in }, receiveValue: {[weak self] model in
                    guard let self = self else { return }
                    dataSource = model
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                })
        } else {
            let task = session.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    print("Empty data. error: ", error ?? "nil")
                    return
                }
                do {
                    let model: DataSource? = try JSONDecoder().decode(DataSource.self, from: data)
                    DispatchQueue.main.async {
                        dataSource = model
                        self.tableView.reloadData()
                        self.refreshControl?.endRefreshing()
                    }
                } catch {
                    print("Error ", error)
                }
            }
            task.resume()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.results.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath) as! RateButtonCell
        cell.textLabel?.text = dataSource?.results[indexPath.row].name
        cell.rateButton.tag = indexPath.row
        cell.rateButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return cell
    }
    
    
    @objc func buttonTapped(_ rateButton: UIButton) {
        rateButton.isSelected.toggle()
        let selectIndex = rateButton.tag
        let eventText = dataSource?.results[selectIndex].name
        if let index = selectedContent.firstIndex(of: eventText!){
            selectedContent.remove(at: index)
        }
        else{
            selectedContent.append(eventText!)
        }

        if rateButton.tag == 0{
            fatalError("App Crash")
        }

        print(selectedContent)
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let event = dataSource?.results[indexPath.row] else { return }
        let detailViewController = DetailViewController(event: event)
        present(detailViewController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

@available(iOS 13.0, *)
class DetailViewController: UIViewController {

    let label = UILabel()
    let imageView = UIImageView()
    let event: DataSource.Event

    @available(iOS 13.0, *)
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

        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        }

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill

        imageView.addSubview(label)
        if #available(iOS 13.0, *) {
            label.backgroundColor = UIColor.systemBackground
            label.textColor = UIColor.secondaryLabel
        }
        label.text = event.name
        label.numberOfLines = 0
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
//        Instana.setView(name: "EventDetail")
    }

    private func loadImage() {
        guard let url = URL(string: event.image_url ?? "") else {
            return
        }
        if #available(iOS 13.0, *) {
            publisher = URLSession.shared.dataTaskPublisher(for: url)
                .receive(on: RunLoop.main)
                .map { UIImage(data: $0.data) }
                .sink(receiveCompletion: { _ in }, receiveValue: {[weak self] image in
                    guard let self = self else { return }
                    self.imageView.image = image
                })
        } else {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    print("Empty data. error: ", error ?? "nil")
                    return
                }
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
            task.resume()
        }
    }
}
