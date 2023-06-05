import XCTest
@testable import InstanaAgent
import Network

class BeaconFlusherTests: InstanaTestCase {

    var corebeacons: [CoreBeacon]!

    override func setUp() {
        super.setUp()
        corebeacons = try! CoreBeaconFactory(.mock).map([HTTPBeacon.createMock()])
    }

    func test_schedule_no_debounce_success() {
        // Given
        let debounce = 0.0
        let timeout: TimeInterval = 1.0
        let flushStart = Date()
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_no_debounce_success")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: debounce,
                                    config: .mock, queue: .main, send: { _, completion in
            completion(.success(200))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: timeout)

        // Then
        XCTAssertEqual(flushResult, .success(corebeacons))
        XCTAssertTrue(Date().timeIntervalSince(flushStart) < timeout)
    }

    func test_schedule_1sec_debounce_success() {
        // Given
        let debounce = 1.0
        let timeout: TimeInterval = 2.0
        let flushStart = Date()
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_1sec_debounce_success")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: debounce,
                                    config: .mock, queue: .main, send: { _, completion in
            completion(.success(200))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: timeout)

        // Then
        XCTAssertEqual(flushResult, .success(corebeacons))
        XCTAssertTrue(Date().timeIntervalSince(flushStart) < debounce + timeout)
    }

    func test_schedule_flush_failure() {
        // Given
        let debounce = 0.0
        let timeout: TimeInterval = 1.0
        let flushStart = Date()
        let error = InstanaError.httpClientError(402)
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_flush_failure")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: debounce,
                                    config: .mock, queue: .main, send: { _, completion in
            completion(.failure(error))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: timeout)

        // Then
        XCTAssertEqual(flushResult, .failure([error]))
        XCTAssertTrue(Date().timeIntervalSince(flushStart) < timeout)
    }

    func test_schedule_flush_success_and_failure() {
        // Given
        let firstBeacon = HTTPBeacon.createMock()
        let secondBeacon = HTTPBeacon.createMock()
        let corebeacons = try! CoreBeaconFactory(.mock).map([firstBeacon, secondBeacon])
        var sentCount = 0
        let config = InstanaConfiguration.mock(maxBeaconsPerRequest: 1, maxQueueSize: 1, debounce: 0, maxRetries: 0)
        let error = InstanaError.httpClientError(402)
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_flush_success_and_failure")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                    config: config, queue: .main, send: { request, completion in
            sentCount += 1
            let content = String(decoding: request.httpBody ?? Data(), as: UTF8.self)
            content.contains("\(secondBeacon.id)") ? completion(.success(200)) : completion(.failure(error))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: 3.0)

        // Then
        XCTAssertEqual(flushResult, .either(sent: [corebeacons.last!], errors: [error]))
        XCTAssertEqual(sentCount, 2)
    }

    func test_schedule_flush_two_success() {
        // Given
        let corebeacons = try! CoreBeaconFactory(.mock).map([HTTPBeacon.createMock(), HTTPBeacon.createMock()])
        var sentCount = 0
        let config = InstanaConfiguration.mock(maxBeaconsPerRequest: 1, maxQueueSize: 1, debounce: 0, maxRetries: 0)
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_flush_success_and_failure")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                    config: config, queue: .main, send: { _, completion in
            sentCount += 1
            completion(.success(200))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: 3.0)

        // Then
        XCTAssertEqual(sentCount, corebeacons.count)
        XCTAssertEqual(flushResult?.sentBeacons.count, corebeacons.count)
        if case let .success(sent) = flushResult {
            // Order is random
            XCTAssertTrue(corebeacons.contains(sent.first!))
            XCTAssertTrue(corebeacons.contains(sent.last!))
            XCTAssertEqual(sentCount, sent.count)
        }
    }

    func test_schedule_flush_two_failures() {
        // Given
        let corebeacons = try! CoreBeaconFactory(.mock).map([HTTPBeacon.createMock(), HTTPBeacon.createMock()])
        var sentCount = 0
        let config = InstanaConfiguration.mock(maxBeaconsPerRequest: 1, maxQueueSize: 1, debounce: 0, maxRetries: 0)
        let error = InstanaError.httpClientError(402)
        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_flush_success_and_failure")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                    config: config, queue: .main, send: { _, completion in
            sentCount += 1
            completion(.failure(error))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: 3.0)

        // Then
        XCTAssertEqual(flushResult, .failure([error, error]))
        XCTAssertEqual(sentCount, 2)
    }

    func test_schedule_flush_failure_retry() {
        // Given
        let maxRetries = 2
        let timeout: TimeInterval = 20.0
        let flushStart = Date()
        var sentCount = 0
        let error = InstanaError.httpClientError(402)
        let expectedErrors = (0...maxRetries).map {_ in error }
        let config = InstanaConfiguration.mock(maxBeaconsPerRequest: 1, maxQueueSize: 1, debounce: 0.0, maxRetries: maxRetries)

        var flushResult: BeaconFlusher.Result?
        let waitFor = expectation(description: "test_schedule_flush_failure_retry")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                    config: config, queue: .main, send: { _, completion in
            sentCount += 1
            completion(.failure(error))
        }, completion: { result in
            flushResult = result
            waitFor.fulfill()
        })

        // When
        flusher.schedule()
        wait(for: [waitFor], timeout: timeout)

        // Then
        XCTAssertEqual(flushResult, .failure(expectedErrors))
        XCTAssertTrue(Date().timeIntervalSince(flushStart) < timeout)
        XCTAssertEqual(sentCount, maxRetries + 1) // Plus the initial send
    }

    func test_cancel() {
        // Given
        let waitFor = expectation(description: "waitForFlushStart")
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: .mock, queue: .main) { _ in }
        flusher.schedule()
        flusher.didStartFlush = {
            waitFor.fulfill()
        }

        // Before
        wait(for: [waitFor], timeout: 1.0)
        XCTAssertEqual(flusher.items.count, 1)
        XCTAssertEqual(flusher.urlTasks.count, 1)

        // When
        flusher.cancel()

        // Then
        XCTAssertEqual(flusher.urlTasks.count, 0)
    }

    func test_urlsession_isIgnored() {
        // Given
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: .mock, queue: .main) { _ in }

        // When
        let isIgnored = IgnoreURLHandler.shouldIgnore(flusher.urlSession)

        // Then
        XCTAssertTrue(isIgnored)
    }

    func test_retryDelay() {
        // Given
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: .mock, queue: .main) { _ in }
        let steps = (1...3)
        let maxDelay = 60 * 10 * 1000

        steps.forEach { step in
            // When
            let delay = flusher.retryDelayMilliseconds(for: step)
            let minimum = Int(pow(2.0, Double(step + 1))) * 1000
            let maxJitter = 1000
            XCTAssertTrue(delay > minimum)
            XCTAssertTrue(delay < (minimum + maxJitter))
        }

        // Verify max delay
        XCTAssertTrue(flusher.retryDelayMilliseconds(for: 8) < maxDelay)
        XCTAssertTrue(flusher.retryDelayMilliseconds(for: 9) == maxDelay)
    }

    func test_shouldPerformRetry_yes() {
        // Given
        let max = 3
        let steps = (1...max)
        let config = InstanaConfiguration.mock(maxRetries: max)
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                    config: config, queue: .main) { _ in }
        flusher.errors.append(InstanaError.invalidResponse)

        steps.forEach { step in
            // When
            let sut = flusher.shouldPerformRetry

            // Then
            XCTAssertTrue(sut())

            // After
            flusher.retryStep = step
        }
        XCTAssertEqual(flusher.retryStep, max)
    }

    func test_shouldPerformRetry_no_error() {
        // Given
        let config = InstanaConfiguration.mock(maxRetries: 10)
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: config, queue: .main) { _ in }

        // Then
        XCTAssertFalse(flusher.shouldPerformRetry())
    }

    func test_shouldPerformRetry_no() {
        // Given
        let config = InstanaConfiguration.mock(maxRetries: 0)
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: config, queue: .main) { _ in }
        flusher.errors.append(InstanaError.invalidResponse)

        // Then
        XCTAssertFalse(flusher.shouldPerformRetry())
    }

    func test_shouldPerformRetry_no_after_last_step() {
        // Given
        let max = 3
        let config = InstanaConfiguration.mock(maxRetries: max)
        let flusher = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0, config: config, queue: .main) { _ in }
        flusher.errors.append(InstanaError.invalidResponse)
        flusher.retryStep = max

        // Then
        XCTAssertFalse(flusher.shouldPerformRetry())
    }

    func test_no_retainCycle() {
        // Given
        let waitFor = expectation(description: "test_no_retainCycle")
        var flusher: BeaconFlusher? = BeaconFlusher(reporter: nil, items: Set(corebeacons), debounce: 0.0,
                                                    config: config, queue: .main, send: { _, completion in
            completion(.success(200))
        }, completion: { result in
            waitFor.fulfill()
        })
        flusher?.schedule()
        weak var weakFlusher = flusher

        // When
        wait(for: [waitFor], timeout: 2.0)
        flusher = nil
        wait(0.1)

        // Then
        XCTAssertNil(weakFlusher)
    }
}

extension BeaconFlusher.Result: Equatable {
    public static func == (lhs: BeaconFlusher.Result, rhs: BeaconFlusher.Result) -> Bool {
        lhs.errors as [NSError] == rhs.errors as [NSError] && lhs.sentBeacons == rhs.sentBeacons
    }
}
