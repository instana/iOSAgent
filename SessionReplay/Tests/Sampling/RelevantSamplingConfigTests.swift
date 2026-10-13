//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay

class RelevantSamplingConfigTests: XCTestCase {

    // MARK: - init (Swift memberwise)

    func test_defaultInit_disabledWithEmptyEventTypes() {
        let config = RelevantSamplingConfig()

        XCTAssertFalse(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.isEmpty)
    }

    func test_init_enabledFalse_emptyEventTypes_succeeds() {
        let config = RelevantSamplingConfig(enabled: false, enableOnEventTypes: Set<RelevantSessionType>())

        XCTAssertFalse(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.isEmpty)
    }

    func test_init_enabledFalse_withEventTypes_succeeds() {
        // enabled=false with non-empty types is valid
        let config = RelevantSamplingConfig(enabled: false, enableOnEventTypes: [.frustration])

        XCTAssertFalse(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.contains(.frustration))
    }

    func test_init_enabledTrue_withFrustration_succeeds() {
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])

        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.contains(.frustration))
    }

    func test_init_enabledTrue_withMultipleEventTypes_storesAll() {
        // If more RelevantSessionType cases are added in future, all must be stored
        let types: Set<RelevantSessionType> = [.frustration]
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: types)

        XCTAssertEqual(config.enableOnEventTypes, types)
    }

    func test_init_storesEnabled_true() {
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        XCTAssertTrue(config.enabled)
    }

    func test_init_storesEnabled_false() {
        let config = RelevantSamplingConfig(enabled: false)
        XCTAssertFalse(config.enabled)
    }

    // MARK: - init (ObjC convenience)

    func test_objcInit_validRawValue_mapsToCorrectType() {
        // .frustration has raw value 1
        let nsSet = NSSet(array: [NSNumber(value: 1)])
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: nsSet)

        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.contains(.frustration))
        XCTAssertEqual(config.enableOnEventTypes.count, 1)
    }

    func test_objcInit_unknownRawValue_isSilentlyDropped() {
        // Raw value 999 does not correspond to any RelevantSessionType case
        let nsSet = NSSet(array: [NSNumber(value: 999)])
        let config = RelevantSamplingConfig(enabled: false, enableOnEventTypes: nsSet)

        XCTAssertTrue(config.enableOnEventTypes.isEmpty)
    }

    func test_objcInit_mixedValidAndInvalidRawValues_keepsOnlyValid() {
        let nsSet = NSSet(array: [NSNumber(value: 1), NSNumber(value: 999)])
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: nsSet)

        XCTAssertEqual(config.enableOnEventTypes.count, 1)
        XCTAssertTrue(config.enableOnEventTypes.contains(.frustration))
    }

    func test_objcInit_emptyNSSet_enabledFalse_succeeds() {
        let config = RelevantSamplingConfig(enabled: false, enableOnEventTypes: NSSet())

        XCTAssertFalse(config.enabled)
        XCTAssertTrue(config.enableOnEventTypes.isEmpty)
    }

    func test_objcInit_nonNSNumberElements_areDropped() {
        // Elements that are not NSNumber are silently ignored by compactMap
        let nsSet = NSSet(array: [NSString("not_a_number"), NSNumber(value: 1)])
        let config = RelevantSamplingConfig(enabled: true, enableOnEventTypes: nsSet)

        XCTAssertTrue(config.enableOnEventTypes.contains(.frustration))
        XCTAssertEqual(config.enableOnEventTypes.count, 1)
    }

    // MARK: - copy(with:) — NSCopying

    func test_copy_producesEqualValues() {
        let original = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])

        let copy = original.copy() as! RelevantSamplingConfig

        XCTAssertEqual(copy.enabled, original.enabled)
        XCTAssertEqual(copy.enableOnEventTypes, original.enableOnEventTypes)
    }

    func test_copy_isDistinctObject() {
        let original = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])

        let copy = original.copy() as! RelevantSamplingConfig

        XCTAssertFalse(copy === original)
    }

    func test_copy_disabledConfig_producesEqualValues() {
        let original = RelevantSamplingConfig(enabled: false)

        let copy = original.copy() as! RelevantSamplingConfig

        XCTAssertFalse(copy.enabled)
        XCTAssertTrue(copy.enableOnEventTypes.isEmpty)
        XCTAssertFalse(copy === original)
    }

    func test_copy_preservesEventTypes() {
        let original = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])

        let copy = original.copy() as! RelevantSamplingConfig

        XCTAssertTrue(copy.enableOnEventTypes.contains(.frustration))
    }

    func test_copyWith_nilZone_succeeds() {
        let original = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])

        let copy = original.copy(with: nil) as! RelevantSamplingConfig

        XCTAssertEqual(copy.enabled, original.enabled)
        XCTAssertEqual(copy.enableOnEventTypes, original.enableOnEventTypes)
    }
}
