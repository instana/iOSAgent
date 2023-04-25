//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class MockInstanaPersistableQueue<T: Codable & Hashable>: InstanaPersistableQueue<T> {

    var addedItems = Set<T>()
    var removedItems = [T]()

    override init(identifier: String, maxItems: Int) {
        super.init(identifier: identifier, maxItems: maxItems)
        // Remove old items first
        items.removeAll()
    }

    override func add(_ item: T, _ completion: Completion? = nil) {
        super.add([item], completion)
        addedItems.insert(item)
    }

    override func remove(_ removalItems: [T], completion: Completion? = nil) {
        super.remove(removalItems, completion: completion)
        removedItems = removalItems
    }
}
