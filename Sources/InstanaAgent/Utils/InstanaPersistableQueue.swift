import Foundation

/// To be used in an asynchronous world (i.e. via a background dispatch queue)
class InstanaPersistableQueue<T: Codable & Equatable> {
    typealias Completion = ((Result<Void, Error>) -> Void)
    let maxItems: Int
    var queueJSONFileURL: URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            Instana.current?.session.logger.add("No Cache directory found", level: .error)
            return nil
        }
        let filename = "\(identifier).instana_queue.json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    var items: [T] = []
    var isFull: Bool { items.count >= maxItems }
    let identifier: String

    init(identifier: String, maxItems: Int) {
        self.maxItems = maxItems
        self.identifier = identifier
        let shouldIgnorePersistence = UserDefaults.standard.bool(forKey: "INSTANA_IGNORE_QUEUE_PERSISTENCE")
        if !shouldIgnorePersistence, let deserializeItems = try? deserialize() {
            items = deserializeItems
        } else {
            items = []
        }
    }

    func write(_ completion: Completion? = nil) {
        guard let fileURL = queueJSONFileURL else { return }
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .completeFileProtection)
            completion?(.success(()))
        } catch {
            completion?(.failure(error))
        }
    }

    func add(_ item: T, _ completion: Completion? = nil) {
        add([item], completion)
    }

    func add(_ newItems: [T], _ completion: Completion? = nil) {
        items.append(contentsOf: newItems)
        write(completion)
    }

    func removeAll(_ completion: Completion? = nil) {
        items.removeAll()
        write(completion)
    }

    func remove(_ removalItems: [T], completion: Completion? = nil) {
        removalItems.forEach { removal in
            items.removeAll(where: { $0 == removal })
        }
        write(completion)
    }

    func deserialize() throws -> [T] {
        guard let fileURL = queueJSONFileURL else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Cache path not found")
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([T].self, from: data)
    }
}
