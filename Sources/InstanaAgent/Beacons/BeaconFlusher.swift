//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import SwiftUI

class BeaconFlusher {
    enum Result {
        case success([CoreBeacon], [ImageBeacon])
        case either(sent: [CoreBeacon], sentImages: [ImageBeacon], errors: [Error])
        case failure([Error])
        var errors: [Error] {
            switch self {
            case let .failure(errors):
                return errors
            case .success:
                return []
            case let .either(sent: _, sentImages: _, errors: errors):
                return errors
            }
        }

        var sentBeacons: [CoreBeacon] {
            switch self {
            case let .success(beacons, _):
                return beacons
            case .failure:
                return []
            case let .either(sent: sent, sentImages: _, errors: _):
                return sent
            }
        }

        var sentImageBeacons: [ImageBeacon] {
            switch self {
            case let .success(_, sentImageBeacons):
                return sentImageBeacons
            case .failure:
                return []
            case let .either(sent: _, sentImages: sentImageBeacons, errors: _):
                return sentImageBeacons
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
    let imageItems: Set<ImageBeacon>
    var didStartFlush: (() -> Void)?
    let urlSession = URLSession(configuration: .default)
    var errors = [Error]()
    var retryStep: Int = 0
    private var flushItem: DispatchWorkItem? {
        willSet {
            flushItem?.cancel()
            cancel()
        }
    }

    private let completion: (BeaconFlusher.Result) -> Void
    private let queue: DispatchQueue
    private let externalSend: Sender? // Used for Unit Testing
    private var sentBeacons = Set<CoreBeacon>()
    private var sentImageBeacons = Set<ImageBeacon>()
    private(set) var urlTasks = [URLSessionTask]()

    init(reporter: Reporter?,
         items: Set<CoreBeacon>,
         imageItems: Set<ImageBeacon>,
         debounce: TimeInterval,
         config: InstanaConfiguration,
         queue: DispatchQueue,
         send: Sender? = nil,
         completion: @escaping ((BeaconFlusher.Result) -> Void)) {
        self.reporter = reporter
        self.items = items
        self.imageItems = imageItems
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
            self?.flush()
        }
        queue.asyncAfter(deadline: .now() + debounce, execute: flushItem)
        self.flushItem = flushItem
    }

    private func flush() {
        let deviceError = reporter?.checkDeviceCondition()
        if deviceError != nil {
            reporter?.session.logger.add("Device is not ready for flush.")
            errors.append(deviceError!)
            complete() // This calls the completion callback with current state
            return
        }

        // flush core beacons
        let batches = items.chunkedBeacons(size: config.maxBeaconsPerRequest)
        let dispatchGroup = DispatchGroup()
        for beaconBatch in batches {
            dispatchGroup.enter()
            let request: URLRequest
            do {
                request = try createBatchRequest(from: beaconBatch.asString)
            } catch {
                errors.append(error)
                dispatchGroup.leave()
                continue
            }
            // Capture the group strongly so leave() is always called even if self (BeaconFlusher)
            // has been deallocated by the time the network callback fires.
            send(request) { [weak self, capturedBeacons = beaconBatch, group = dispatchGroup] sentResult in
                guard let self else {
                    // BeaconFlusher was deallocated; nothing to mutate, but
                    // leave() must still be called so notify can fire.
                    group.leave()
                    return
                }
                // Dispatch mutations onto the serial reporter queue so that
                // sentBeacons/errors are only ever written from one thread.
                // leave() is called inside the async block so notify cannot fire
                // until after the mutation has been committed — preserving the
                // invariant that complete() always sees fully-updated state.
                self.queue.async {
                    switch sentResult {
                    case .success:
                        self.sentBeacons.formUnion(capturedBeacons)
                    case let .failure(error):
                        self.errors.append(error)
                    }
                    group.leave()
                }
            }
        }

        // flush image beacons
        for imageBeacon in imageItems {
            guard let request = createImageRequest(imageBeacon: imageBeacon) else {
                continue
            }
            dispatchGroup.enter()
            send(request) { [weak self, capturedImageBeacon = imageBeacon, group = dispatchGroup] sentResult in
                guard let self else {
                    group.leave()
                    return
                }
                self.queue.async {
                    switch sentResult {
                    case .success:
                        self.sentImageBeacons.insert(capturedImageBeacon)
                    case let .failure(error):
                        self.errors.append(error)
                    }
                    group.leave()
                }
            }
        }

        dispatchGroup.notify(queue: queue) { [self] in
            self.urlTasks.removeAll()
            self.complete()
//            if self.shouldPerformRetry() {
//                self.retry()
//            } else {
//                self.complete()
//            }
        }
        didStartFlush?()
    }

    // When error occurred, either goes into slow send mode, or retry sending.
    internal func shouldPerformRetry() -> Bool {
        guard !errors.isEmpty else {
            return false
        }
        return retryStep < config.maxRetries
    }

//    private func retry() {
//        retryStep += 1
//        queue.asyncAfter(deadline: .now() + .milliseconds(retryDelayMilliseconds(for: retryStep)), execute: flush)
//    }

    private func complete() {
        if !errors.isEmpty, !sentBeacons.isEmpty || !sentImageBeacons.isEmpty {
            completion(.either(sent: Array(sentBeacons), sentImages: Array(sentImageBeacons), errors: errors))
        } else if !errors.isEmpty {
            completion(.failure(errors))
        } else {
            completion(.success(Array(sentBeacons), Array(sentImageBeacons)))
        }
    }

    // MARK: Network

    func send(_ request: URLRequest, completion: @escaping (Swift.Result<Int, Error>) -> Void) {
        if let external = externalSend {
            return external(request, completion)
        }
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(InstanaError.create(from: error)))
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(InstanaError.invalidResponse))
            }
            switch httpResponse.statusCode {
            case 200:
                self.reporter?.runtimeConfig.handleSRConfigResponse(data: data)
                completion(.success(httpResponse.statusCode))
            case 201 ... 399:
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

        // Default timeout interval 1 minute from URLRequest is too short for some networks.
        // Increase the interval to 2 minutes by default and also make it configurable to the app.
        urlRequest.timeoutInterval = config.timeoutInterval

        reporter?.runtimeConfig.setSRConfigHeader(&urlRequest, srStatus: reporter?.session.sessionReplayStatus)

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

    // MARK: Network for image beacons

    func createImageRequest(imageBeacon: ImageBeacon) -> URLRequest? {
        let reportingURL = URL(string: "\(config.reportingURL.absoluteString)/eum/images")!
//        let reportingURL = URL(string: "http://localhost:2999/mobile/eum/images")! // save to local file

        var request = URLRequest(url: reportingURL)
        request.httpMethod = "POST"

        reporter?.runtimeConfig.setSRConfigHeader(&request, srStatus: reporter?.session.sessionReplayStatus)

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Append text fields
        var meta = imageBeacon.meta
        meta["timestamp"] = String(imageBeacon.ti)
        let imageFormat = meta["imageFormat"]
        guard let metaData = try? JSONSerialization.data(withJSONObject: meta, options: []),
            let metaString = String(data: metaData, encoding: .utf8) else {
            reporter?.session.logger.add("Failed to serialize image beacon dictionary to JSON", level: .warning)
            return nil
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"metadata\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(metaString)\r\n".data(using: .utf8)!)

        if imageBeacon.img != nil, imageFormat != nil {
            // Append file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=image\r\n".data(using: .utf8)!)
            let contentTypeStr = "Content-Type: image/" + imageFormat! + "\r\n\r\n"
            body.append(contentTypeStr.data(using: .utf8)!)
            body.append(imageBeacon.img!)
            body.append("\r\n".data(using: .utf8)!)
        }

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        return request
    }
}
