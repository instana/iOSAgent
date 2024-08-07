import XCTest

extension InstanaTestCase {
    func selfCleaningTempFileURL(name: String, file: StaticString = #file, line: UInt = #line) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        
        addTeardownBlock {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), file: file, line: line)
                }
            } catch {
                XCTFail("Error while deleting temporary file: \(error)", file: file, line: line)
            }
        }
        return url
    }

    func wait(_ duration: TimeInterval, timeout: TimeInterval = 60.0) {
        let waiting = expectation(description: "waitfor")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            waiting.fulfill()
        }
        wait(for: [waiting], timeout: timeout)
    }

    func run(after: TimeInterval, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            action()
        }
    }
}

func AssertEqualAndNotNil<T: Equatable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(try expression1(), try expression2(), message(), file: file, line: line)
    XCTAssertNotNil(try expression1(), message(), file: file, line: line)
    XCTAssertNotNil(try expression2(), message(), file: file, line: line)
}

func AssertTrue(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(try expression(), message(), file: file, line: line)
}

func AssertFalse(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertFalse(try expression(), message(), file: file, line: line)
}

func AssertEqualAndNotZero<T: Numeric & Comparable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(try expression1() > 0, message(), file: file, line: line)
    XCTAssertTrue(try expression2() > 0, message(), file: file, line: line)
    XCTAssertEqual(try expression1(), try expression2(), message(), file: file, line: line)
}

extension InstanaTestCase {
    enum ComparisonType {
        case shouldBeNil
        case nonEmptyString
        case greaterThanZero
    }
    
    func compareDictionaries(original: [String: Any], expected: [String: Any], file: StaticString = #file, line: UInt = #line) {
        expected.forEach { key, value in
            switch value {
            case ComparisonType.shouldBeNil:
                XCTAssertNil(original[key], file: file, line: line)
            case ComparisonType.nonEmptyString:
                XCTAssert((original[key] as? String)?.isEmpty == false, file: file, line: line)
            case ComparisonType.greaterThanZero:
                switch original[key] {
                    case let n as Double:
                        XCTAssert(n > 0, file: file, line: line)
                    case let n as Float:
                        XCTAssert(n > 0, file: file, line: line)
                    case let n as Int:
                        XCTAssert(n > 0, file: file, line: line)
                    default:
                        XCTFail("'\(String(describing: original[key]))' is not greater than 0", file: file, line: line)
                }
            case let expectedSubDict as [String: Any]:
                if let originalSubDict = original[key] as? [String: Any] {
                    compareDictionaries(original: originalSubDict, expected: expectedSubDict, file: file, line: line)
                }
                else {
                    XCTFail("Value for key '\(key)' is not a dictionary", file: file, line: line)
                }
            case let expectedSubArray as NSArray:
                if let originalSubArray = original[key] as? NSArray {
                    XCTAssertEqual(originalSubArray, expectedSubArray)
                }
                else {
                    XCTFail("Value for key '\(key)' is not an array", file: file, line: line)
                }
            case let string as String:
                XCTAssertEqual(original[key] as? String, string, file: file, line: line)
            case let n as Double:
                XCTAssertEqual(original[key] as? Double, n, file: file, line: line)
            case let n as Float:
                XCTAssertEqual(original[key] as? Float, n, file: file, line: line)
            case let n as Int:
                XCTAssertEqual(original[key] as? Int, n, file: file, line: line)
            case let n as Int64:
                XCTAssertEqual(original[key] as? Int64, n, file: file, line: line)
            default:
                XCTFail("Unhandled comparison \(type(of: value))", file: file, line: line)
            }
        }
    }
}
