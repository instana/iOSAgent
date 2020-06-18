import Foundation
import XCTest
@testable import InstanaAgent

class MockInstanaPersistableQueue<T: Codable & Equatable>: InstanaPersistableQueue<T> {

    var addedItems = [T]()
    var removedItems = [T]()

    override func add(_ item: T, _ completion: Completion? = nil) {
        super.add([item], completion)
        addedItems.append(item)
    }

    override func add(_ newItems: [T], _ completion: Completion? = nil) {
        super.add(newItems, completion)
        addedItems.append(contentsOf: newItems)
    }

    override func remove(_ removalItems: [T], completion: Completion? = nil) {
        super.remove(removalItems, completion: completion)
        removedItems = removalItems
    }
}
