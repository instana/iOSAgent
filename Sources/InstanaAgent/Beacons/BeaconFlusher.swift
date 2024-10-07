//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import SwiftUI

class BeaconFlusher {
    enum Result {
        case success([CoreBeacon])
        case either(sent: [CoreBeacon], errors: [Error])
        case failure([Error])
        var errors: [Error] {
            switch self {
            case let .failure(errors):
                return errors
            case .success:
                return []
            case let .either(sent: _, errors: errors):
                return errors
            }
        }

        var sentBeacons: [CoreBeacon] {
            switch self {
            case let .success(beacons):
                return beacons
            case .failure:
                return []
            case let .either(sent: sent, errors: _):
                return sent
            }
        }
    }

    func retryDelayMilliseconds(for retry: Int) -> Int {
        let maxDelay = 60 * 10 * 1000
        var delay = Int(pow(2.0, Double(retry + 1))) * 1000
        let jitter = Int.random(in: 0 ... 1000)
        delay = min(delay + jitter, maxDelay)
        return delay
    }

    typealias Sender = (URLRequest, @escaping (Swift.Result<Int, Error>) -> Void) -> Void
    weak var reporter: Reporter?
    let config: InstanaConfiguration
    let debounce: TimeInterval
    let items: Set<CoreBeacon>
    var didStartFlush: (() -> Void)?
    let urlSession = URLSession(configuration: .default)
    var errors = [Error]()
    var retryStep: Int = 0
    private weak var flushItem: DispatchWorkItem? {
        willSet {
            flushItem?.cancel()
            cancel()
        }
    }

    private let completion: (BeaconFlusher.Result) -> Void
    private let queue: DispatchQueue
    private let externalSend: Sender? // Used for Unit Testing
    private var sentBeacons = Set<CoreBeacon>()
    private(set) var urlTasks = [URLSessionTask]()

    init(reporter: Reporter?,
         items: Set<CoreBeacon>,
         debounce: TimeInterval,
         config: InstanaConfiguration,
         queue: DispatchQueue,
         send: Sender? = nil,
         completion: @escaping ((BeaconFlusher.Result) -> Void)) {
        self.reporter = reporter
        self.items = items
        self.config = config
        self.debounce = debounce
        self.completion = completion
        self.queue = queue
        externalSend = send
        Instana.ignore(urlSession)
    }

    deinit {
        flushItem?.cancel()
        cancel()
    }

    func schedule() {
        let flushItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.flush()
        }
        queue.asyncAfter(deadline: .now() + debounce, execute: flushItem)
        self.flushItem = flushItem
    }

    private func flush() {
        let batches = items.chunkedBeacons(size: config.maxBeaconsPerRequest)
        let disapatchGroup = DispatchGroup()
        batches.forEach { beaconBatch in
            disapatchGroup.enter()
            let request: URLRequest
            do {
                request = try createBatchRequest(from: beaconBatch.asString)
            } catch {
                errors.append(error)
                disapatchGroup.leave()
                return
            }
            send(request) { [weak self] sentResult in
                guard let self = self else { return }
                switch sentResult {
                case .success:
                    self.sentBeacons.formUnion(beaconBatch)
                case let .failure(error):
                    self.errors.append(error)
                }
                disapatchGroup.leave()
            }
        }
        disapatchGroup.notify(queue: queue) { [weak self] in
            guard let self = self else { return }
            self.urlTasks.removeAll()
            if self.shouldPerformRetry() {
                self.retry()
            } else {
                self.complete()
            }
        }
        didStartFlush?()
    }

    // When error occurred, either goes into slow send mode, or retry sending.
    internal func shouldPerformRetry() -> Bool {
        let canDoSlowSend = config.slowSendInterval > 0

        guard !errors.isEmpty else {
            if canDoSlowSend {
                // No error, reset the flag
                reporter?.setSlowSendStartTime(nil)
            }
            return false
        }

        if canDoSlowSend {
            reporter?.setSlowSendStartTime(Date())
            return false
        }
        return retryStep < config.maxRetries
    }

    private func retry() {
        retryStep += 1
        queue.asyncAfter(deadline: .now() + .milliseconds(retryDelayMilliseconds(for: retryStep)), execute: flush)
    }

    private func complete() {
        if !errors.isEmpty, !sentBeacons.isEmpty {
            completion(.either(sent: Array(sentBeacons), errors: errors))
        } else if !errors.isEmpty {
            completion(.failure(errors))
        } else {
            completion(.success(Array(sentBeacons)))
        }
    }

    // MARK: Network

    func send(_ request: URLRequest, completion: @escaping (Swift.Result<Int, Error>) -> Void) {
        if let external = externalSend {
            return external(request, completion)
        }
        let task = urlSession.dataTask(with: request) { _, response, error in
            if let error = error {
                return completion(.failure(InstanaError.create(from: error)))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(InstanaError.invalidResponse))
            }
            switch httpResponse.statusCode {
            case 200 ... 399:
                completion(.success(httpResponse.statusCode))
            case 400 ... 499:
                completion(.failure(InstanaError.httpClientError(httpResponse.statusCode)))
            case 500 ... 599:
                completion(.failure(InstanaError.httpServerError(httpResponse.statusCode)))
            default:
                completion(.failure(InstanaError.invalidResponse))
            }
        }
        urlTasks.append(task)
        task.resume()
    }

    func cancel() {
        urlTasks.forEach { task in
            if task.state == .running {
                task.cancel()
            }
        }
        urlTasks.removeAll()
    }

    func createBatchRequest(from beacons: String) throws -> URLRequest {
        guard !config.key.isEmpty else {
            throw InstanaError.missingAppKey
        }

        var urlRequest = URLRequest(url: config.reportingURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("text/plain", forHTTPHeaderField: "Content-Type")

        let data = beacons.data(using: .utf8)

        if config.gzipReport, let gzippedData = try? data?.gzipped(level: .bestCompression) {
            urlRequest.httpBody = gzippedData
            urlRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            urlRequest.setValue("\(gzippedData.count)", forHTTPHeaderField: "Content-Length")
        } else {
            urlRequest.httpBody = data
            urlRequest.setValue("\(data?.count ?? 0)", forHTTPHeaderField: "Content-Length")
        }

        return urlRequest
    }
}
