import Foundation
import XCTest
@testable import InstanaAgent

class MockInstanaPersistableQueue<T: Codable & Hashable>: InstanaPersistableQueue<T> {

    var addedItems = Set<T>()

    override func add(_ item: T, _ completion: Completion? = nil) {
        super.add([item], completion)
        addedItems.insert(item)
    }

    override func add(_ newItems: [T], _ completion: Completion? = nil) {
        super.add(newItems, completion)
        addedItems.formUnion(newItems)
    }
}
