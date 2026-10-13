//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

class WeakRef<T: AnyObject> {
    weak var value: T?
    init(_ value: T?) { self.value = value }
}
