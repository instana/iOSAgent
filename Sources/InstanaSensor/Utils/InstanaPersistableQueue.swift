//
//  File.swift
//  
//
//  Created by Christian Menschel on 06.12.19.
//

import Foundation

// TODO: Use Ooperation queue later
struct InstanaPersistableQueue<T: Codable & Equatable>: Codable {
    var items: [T]

    init() {
        self.items = []
        read()
    }

    init(_ items: [T]) {
        self.items = items
        read()
    }

    private mutating func read() {
        if let persisted = try? InstanaPersistableQueue<T>.read() {
            items.append(contentsOf: persisted.items)
        }
    }

    static var queueJSONFileURL: URL? {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first else {
            debugAssertFailure("No Cache directory found")
            return nil
        }
        let typeName = type(of: self)
        let filename = ".instana_\(typeName)_queue.json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    func write() {
        guard let fileURL = InstanaPersistableQueue.queueJSONFileURL else { return }
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL, options: .completeFileProtection)
        } catch {
            Instana.current.logger.add("Could not write queue to file \(fileURL)", level: .error)
        }
    }

    mutating func add(_ item: T) {
        add([item])
    }

    mutating func add(_ newItems: [T]) {
        items.append(contentsOf: newItems)
        write()
    }

    mutating func removeAll() {
        items.removeAll()
        write()
    }

    mutating func remove(_ removalItems: [T]) {
        removalItems.forEach { removal in
            items.removeAll(where: {$0 == removal})
        }
        write()
    }

    static func read() throws -> Self {
        guard let fileURL = InstanaPersistableQueue.queueJSONFileURL else {
            throw InstanaError(code: InstanaError.Code.invalidRequest, description: "Cache path not found")
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
