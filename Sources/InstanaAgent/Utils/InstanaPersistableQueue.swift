import Foundation

/// To be used in an asynchronous world (i.e. via a background dispatch queue)
class InstanaPersistableQueue<T: Codable & Equatable> {
    typealias Completion = ((Result<Void, Error>) -> Void)
    let maxItems: Int
    static var queueJSONFileURL: URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            debugAssertFailure("No Cache directory found")
            return nil
        }
        let typeName = String(describing: self)
        let filename = ".instana_\(typeName)_queue.json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    static func reset() {
        guard let fileURL = InstanaPersistableQueue.queueJSONFileURL else { return }
        let fileManager = FileManager()
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Could not reset queue at \(fileURL)")
        }
    }

    var items: [T]
    var isFull: Bool { items.count >= maxItems }

    init(maxItems: Int) {
        self.maxItems = maxItems
        if let deserializeItems = try? InstanaPersistableQueue<T>.deserialize() {
            items = deserializeItems
        } else {
            items = []
        }
    }

    func write(_ completion: Completion? = nil) {
        guard let fileURL = InstanaPersistableQueue.queueJSONFileURL else { return }
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

    static func deserialize() throws -> [T] {
        guard let fileURL = InstanaPersistableQueue.queueJSONFileURL else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Cache path not found")
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([T].self, from: data)
    }
}
