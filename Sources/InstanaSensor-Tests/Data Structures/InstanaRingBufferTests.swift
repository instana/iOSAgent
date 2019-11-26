//  Created by Nikola Lajic on 3/5/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import iOSSensor

class InstanaRingBufferTests: XCTestCase {

    func test_initilizedBuffer_shouldBeEmpty() {
        let buffer = InstanaRingBuffer<Int>(size: 10)
        XCTAssertTrue(buffer.isEmpty)
    }
    
    func test_unfilledBuffer_shouldNotBeFullOrEmpty() {
        var buffer = InstanaRingBuffer<Int>(size: 10)
        buffer.write(1)
        XCTAssertFalse(buffer.isEmpty)
        XCTAssertFalse(buffer.isFull)
    }
    
    func test_filledBuffer_shouldBeReportedAsFull() {
        var buffer = InstanaRingBuffer<Int>(size: 3)
        buffer.write(1)
        buffer.write(1)
        buffer.write(2)
        XCTAssertFalse(buffer.isEmpty)
        XCTAssertTrue(buffer.isFull)
    }
    
    func test_elements_shouldBeReturnedFIFO() {
        var buffer = InstanaRingBuffer<Int>(size: 3)
        buffer.write(1)
        buffer.write(2)
        XCTAssertEqual(buffer.read(), 1)
        XCTAssertEqual(buffer.read(), 2)
    }
    
    func test_bufferState_shouldBeUpdatedAfterRead() {
        var buffer = InstanaRingBuffer<Int>(size: 1)
        
        buffer.write(1)
        XCTAssertFalse(buffer.isEmpty)
        XCTAssertTrue(buffer.isFull)
        
        _ = buffer.read()
        XCTAssertTrue(buffer.isEmpty)
        XCTAssertFalse(buffer.isFull)
    }
    
    func test_readAll_shouldReturnAllElements() {
        var buffer = InstanaRingBuffer<Int>(size: 10)
        
        buffer.write(1)
        buffer.write(2)
        buffer.write(3)
        
        XCTAssertEqual(buffer.readAll(), [1, 2, 3])
        XCTAssertTrue(buffer.isEmpty)
    }
    
    func test_fullBuffer_shouldOverwriteEarliestElement() {
        var buffer = InstanaRingBuffer<Int>(size: 3)
        
        buffer.write(1)
        buffer.write(2)
        buffer.write(3)
        buffer.write(4)
        
        XCTAssertEqual(buffer.readAll(), [2, 3, 4])
        
        buffer.write(1)
        buffer.write(2)
        buffer.write(3)
        buffer.write(4)
        buffer.write(5)
        buffer.write(6)
        XCTAssertEqual(buffer.readAll(), [4, 5, 6])
    }
}
