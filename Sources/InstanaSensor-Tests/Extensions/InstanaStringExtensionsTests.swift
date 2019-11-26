//  Created by Nikola Lajic on 3/4/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class InstanaStringExtensionsTests: XCTestCase {
    
    func test_safeTruncation_withNoComposedCharacters() {
        XCTAssertEqual("a".safelyTruncated(to: 10), "a")
        XCTAssertEqual("a".safelyTruncated(to: 0), "")
        XCTAssertEqual("abc".safelyTruncated(to: 1), "a")
        XCTAssertEqual("".safelyTruncated(to: 100), "")
    }

    func test_safeTruncation_withComposedCharacters() {
        XCTAssertEqual("👩‍👩‍👦‍👦".safelyTruncated(to: 1), "")
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: 1), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: 2), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: 25), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: 26), "a👩‍👩‍👦‍👦")
        XCTAssertEqual("a👯‍♀️".safelyTruncated(to: 13), "a")
        XCTAssertEqual("a👯‍♀️".safelyTruncated(to: 14), "a👯‍♀️")
        
    }
    
    func test_safeTruncation_withMultipleComposedCharacters() {
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 1), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 2), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 25), "a")
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 26), "a👩‍👩‍👦‍👦")
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 50), "a👩‍👩‍👦‍👦")
        XCTAssertEqual("a👩‍👩‍👦‍👦👩‍👩‍👦‍👦".safelyTruncated(to: 51), "a👩‍👩‍👦‍👦👩‍👩‍👦‍👦")
    }
    
    func test_safeTruncation_withExtremeValues() {
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: 0), "")
        XCTAssertEqual("a👩‍👩‍👦‍👦".safelyTruncated(to: UInt.max), "a👩‍👩‍👦‍👦")
    }
    
    func test_nsstring_safeTruncation() {
        let nsstring = NSString(string: "a👩‍👩‍👦‍👦")
        XCTAssertEqual(nsstring.safelyTruncated(to: 1), "a")
        XCTAssertEqual(nsstring.safelyTruncated(to: 2), "a")
        XCTAssertEqual(nsstring.safelyTruncated(to: 25), "a")
        XCTAssertEqual(nsstring.safelyTruncated(to: 26), "a👩‍👩‍👦‍👦")
    }
}
