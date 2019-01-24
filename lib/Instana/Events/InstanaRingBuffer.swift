//  Created by Nikola Lajic on 12/31/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

struct InstanaRingBuffer<T> {
    private var contents: [T?]
    private var readIndex = 0
    private var writeIndex = 0
    
    init(size: Int) {
        contents = [T?](repeating: nil, count: size)
    }
    
    @discardableResult
    mutating func write(_ element: T) -> Bool {
        guard isFull == false else { return false }
        contents[writeIndex % contents.count] = element
        writeIndex += 1
        return true
    }
    
    mutating func read() -> T? {
        guard isEmpty == false else { return nil }
        let element = contents[readIndex % contents.count]
        readIndex += 1
        return element
    }
    
    mutating func readAll() -> [T] {
        var elements: [T] = []
        while isEmpty == false {
            if let element = read() {
                elements.append(element)
            }
        }
        return elements
    }
    
    var isEmpty: Bool {
        return availableSpaceForReading == 0
    }
    
    var isFull: Bool {
        return availableSpaceForWriting == 0
    }
    
    var availableSpaceForWriting: Int {
        return contents.count - availableSpaceForReading
    }
    
    var availableSpaceForReading: Int {
        return writeIndex - readIndex
    }
}
