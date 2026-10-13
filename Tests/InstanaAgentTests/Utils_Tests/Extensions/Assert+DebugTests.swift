//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class AssertDebugTests: InstanaTestCase {

    // MARK: - debugAssertFailure

    func test_debugAssertFailure_doesNotTrapDuringTests() {
        // When running under XCTest, isRunningTests is true so assertionFailure
        // is never reached. Calling this must not crash.
        debugAssertFailure()
    }

    func test_debugAssertFailure_withMessage_doesNotTrapDuringTests() {
        debugAssertFailure("should never trap in test context")
    }

    // MARK: - debugAssert

    func test_debugAssert_trueCondition_doesNotTrapDuringTests() {
        // A passing condition in normal code — must not crash in test context.
        debugAssert(true)
    }

    func test_debugAssert_falseCondition_doesNotTrapDuringTests() {
        // In production this would crash, but isRunningTests suppresses assert().
        debugAssert(false)
    }

    func test_debugAssert_falseConditionWithMessage_doesNotTrapDuringTests() {
        debugAssert(false, "should never trap in test context")
    }

    func test_debugAssert_conditionClosureIsNotEvaluatedDuringTests() {
        // Because the guard `!ProcessInfo.isRunningTests` short-circuits before
        // assert() is called, the condition autoclosure must never be executed
        // when running under XCTest.
        var evaluated = false
        debugAssert({
            evaluated = true
            return false
        }())
        XCTAssertFalse(evaluated, "condition closure must not be evaluated during tests")
    }

    func test_debugAssertFailure_isRunningTestsFlagIsTrue() {
        // Validate the precondition the functions rely on: the test environment
        // always sets XCTestConfigurationFilePath, so isRunningTests is true.
        XCTAssertTrue(ProcessInfo.isRunningTests)
    }
}
