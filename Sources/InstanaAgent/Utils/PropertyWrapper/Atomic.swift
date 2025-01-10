//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

/// Don't use this propertyWrapper for value types, esp. Collections (Array, Dictionary, Set)
/// This can have unexpected results: see https://www.donnywals.com/why-your-atomic-property-wrapper-doesnt-work-for-collection-types/
@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get { lock.atomic { value } }
        set { lock.atomic { value = newValue } }
    }
}

extension NSLock {
    func atomic<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try closure()
    }
}

// Inspired by donnywals https://www.donnywals.com/why-your-atomic-property-wrapper-doesnt-work-for-collection-types/
// We must make this a reference type to avoid getting a copy for each different thread (expected value type behavior)
class AtomicDictionary<Key: Hashable, Value>: CustomDebugStringConvertible {
    private var dict = [Key: Value]()
    private let lock = NSLock()

    subscript(key: Key) -> Value? {
        get { lock.atomic { dict[key] } }
        set { lock.atomic { dict[key] = newValue } }
    }

    var debugDescription: String {
        lock.atomic { dict.debugDescription }
    }
}

extension AtomicDictionary: Equatable where Value: Equatable {
    static func == (lhs: AtomicDictionary<Key, Value>, rhs: AtomicDictionary<Key, Value>) -> Bool {
        lhs.dict == rhs.dict
    }
}

class AtomicArray<T>: CustomDebugStringConvertible, Sequence, Collection {
    private var array: [T]
    private let lock = NSLock()

    var startIndex: Int {
        lock.atomic { array.startIndex }
    }

    var endIndex: Int {
        lock.atomic { array.endIndex }
    }

    init(_ array: [T] = []) {
        self.array = array
    }

    subscript(index: Int) -> T {
        get { lock.atomic { array[index] } }
        set { lock.atomic { array[index] = newValue } }
    }

    func append(_ newElement: T) {
        lock.atomic { array.append(newElement) }
    }

    var debugDescription: String {
        lock.atomic { array.debugDescription }
    }

    func removeAll() {
        lock.atomic { array.removeAll() }
    }

    func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        try lock.atomic {
            try array.removeAll(where: shouldBeRemoved)
        }
    }

    func index(after index: Int) -> Int {
        lock.atomic {
            array.index(after: index)
        }
    }

    func index(before index: Int) -> Int {
        lock.atomic {
            array.index(before: index)
        }
    }

    func makeIterator() -> IndexingIterator<[T]> {
        lock.lock()
        defer { lock.unlock() }
        return array.makeIterator()
    }
}

extension AtomicArray: Equatable where T: Equatable {
    func contains(_ element: T) -> Bool {
        lock.atomic { array.contains(element) }
    }

    static func == (lhs: AtomicArray<T>, rhs: AtomicArray<T>) -> Bool {
        lhs.array == rhs.array
    }
}

class AtomicSet<T: Hashable>: CustomDebugStringConvertible, Sequence {
    private var set: Set<T>
    private let lock = NSLock()

    init(_ set: [T] = []) {
        self.set = Set(set)
    }

    func contains(_ member: T) -> Bool {
        lock.atomic { set.contains(member) }
    }

    @discardableResult func insert(_ newMember: T) -> (inserted: Bool, memberAfterInsert: T) {
        lock.atomic { set.insert(newMember) }
    }

    var debugDescription: String {
        lock.atomic { set.debugDescription }
    }

    func makeIterator() -> Set<T>.Iterator {
        lock.lock()
        defer { lock.unlock() }
        return set.makeIterator()
    }

    func formUnion<S>(_ other: S) where T == S.Element, S: Sequence {
        lock.atomic { set.formUnion(other) }
    }

    func removeAll() {
        lock.atomic { set.removeAll() }
    }

    @discardableResult func remove(_ toRemove: T) -> T? {
        var removed: T?
        lock.atomic { removed = set.remove(toRemove) }
        return removed
    }

    var count: Int {
        lock.atomic { set.count }
    }

    var first: T? {
        lock.atomic { set.first }
    }
}

extension AtomicSet: Equatable {
    static func == (lhs: AtomicSet<T>, rhs: AtomicSet<T>) -> Bool {
        lhs.set == rhs.set
    }
}
