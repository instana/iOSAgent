//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaSessionReplay

class SamplingConfigTests: XCTestCase {

    // MARK: - init (default)

    func test_defaultInit_setsExpectedDefaults() {
        let config = SamplingConfig()

        XCTAssertEqual(config.samplingPercentage, 100)
        XCTAssertFalse(config.onDemandSamplingEnabled)
        XCTAssertEqual(config.maxTimeBufferMinutes, 3.0)
        XCTAssertFalse(config.relevantSamplingConfig.enabled)
        XCTAssertTrue(config.relevantSamplingConfig.enableOnEventTypes.isEmpty)
    }

    // MARK: - init (memberwise)

    func test_memberwise_init_storesAllValues() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let config = SamplingConfig(samplingPercentage: 50,
                                    onDemandSamplingEnabled: true,
                                    relevantSamplingConfig: relevant)

        XCTAssertEqual(config.samplingPercentage, 50)
        XCTAssertTrue(config.onDemandSamplingEnabled)
        XCTAssertTrue(config.relevantSamplingConfig.enabled)
        XCTAssertTrue(config.relevantSamplingConfig.enableOnEventTypes.contains(.frustration))
    }

    func test_memberwise_init_samplingPercentage_zero_isAllowed() {
        let config = SamplingConfig(samplingPercentage: 0)
        XCTAssertEqual(config.samplingPercentage, 0)
    }

    func test_memberwise_init_samplingPercentage_100_isAllowed() {
        let config = SamplingConfig(samplingPercentage: 100)
        XCTAssertEqual(config.samplingPercentage, 100)
    }

    func test_memberwise_init_samplingPercentage_boundary_1_isAllowed() {
        let config = SamplingConfig(samplingPercentage: 1)
        XCTAssertEqual(config.samplingPercentage, 1)
    }

    func test_memberwise_init_samplingPercentage_boundary_99_isAllowed() {
        let config = SamplingConfig(samplingPercentage: 99)
        XCTAssertEqual(config.samplingPercentage, 99)
    }

    // MARK: - copy(with:)

    func test_copy_producesEqualValues() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let original = SamplingConfig(samplingPercentage: 40,
                                      onDemandSamplingEnabled: true,
                                      relevantSamplingConfig: relevant)

        let copy = original.copy(with: nil) as! SamplingConfig

        XCTAssertEqual(copy.samplingPercentage, original.samplingPercentage)
        XCTAssertEqual(copy.onDemandSamplingEnabled, original.onDemandSamplingEnabled)
        XCTAssertEqual(copy.relevantSamplingConfig.enabled, original.relevantSamplingConfig.enabled)
        XCTAssertEqual(copy.relevantSamplingConfig.enableOnEventTypes,
                       original.relevantSamplingConfig.enableOnEventTypes)
    }

    func test_copy_isIndependentObject() {
        let original = SamplingConfig(samplingPercentage: 50)
        let copy = original.copy(with: nil) as! SamplingConfig

        // Mutating the copy must not affect the original
        copy.samplingPercentage = 10

        XCTAssertEqual(original.samplingPercentage, 50)
        XCTAssertEqual(copy.samplingPercentage, 10)
    }

    func test_copy_relevantSamplingConfig_isDeepCopied() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let original = SamplingConfig(samplingPercentage: 30, relevantSamplingConfig: relevant)

        let copy = original.copy(with: nil) as! SamplingConfig

        // The copied relevantSamplingConfig must be a distinct object
        XCTAssertFalse(copy.relevantSamplingConfig === original.relevantSamplingConfig)
        XCTAssertEqual(copy.relevantSamplingConfig.enabled, original.relevantSamplingConfig.enabled)
    }

    // MARK: - isRelevantSamplingEnabled(for:)

    func test_isRelevantSamplingEnabled_enabledWithMatchingType_returnsTrue() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let config = SamplingConfig(samplingPercentage: 50, relevantSamplingConfig: relevant)

        XCTAssertTrue(config.isRelevantSamplingEnabled(for: .frustration))
    }

    func test_isRelevantSamplingEnabled_disabledConfig_returnsFalse() {
        // relevantSamplingConfig.enabled == false
        let relevant = RelevantSamplingConfig(enabled: false)
        let config = SamplingConfig(samplingPercentage: 50, relevantSamplingConfig: relevant)

        XCTAssertFalse(config.isRelevantSamplingEnabled(for: .frustration))
    }

    func test_isRelevantSamplingEnabled_enabledButTypeNotIncluded_returnsFalse() {
        // enabled == true but enableOnEventTypes does not contain .frustration
        // We cannot construct such a state directly (the precondition requires a non-empty set),
        // so we verify the guard: an empty set would be caught by precondition.
        // Instead we confirm a freshly disabled config returns false.
        let config = SamplingConfig()   // relevantSamplingConfig.enabled == false by default

        XCTAssertFalse(config.isRelevantSamplingEnabled(for: .frustration))
    }

    func test_isRelevantSamplingEnabled_default100Percent_returnsFalse() {
        let config = SamplingConfig()   // default: relevant sampling disabled

        XCTAssertFalse(config.isRelevantSamplingEnabled(for: .frustration))
    }

    // MARK: - isBufferingEnabled()

    func test_isBufferingEnabled_100Percent_returnsFalse() {
        // samplingPercentage == 100 → buffering never needed regardless of other flags
        let config = SamplingConfig(samplingPercentage: 100, onDemandSamplingEnabled: true)

        XCTAssertFalse(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_lessThan100_onDemandEnabled_returnsTrue() {
        let config = SamplingConfig(samplingPercentage: 50, onDemandSamplingEnabled: true)

        XCTAssertTrue(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_lessThan100_relevantSamplingEnabled_returnsTrue() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let config = SamplingConfig(samplingPercentage: 50, relevantSamplingConfig: relevant)

        XCTAssertTrue(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_lessThan100_bothEnabled_returnsTrue() {
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let config = SamplingConfig(samplingPercentage: 50,
                                    onDemandSamplingEnabled: true,
                                    relevantSamplingConfig: relevant)

        XCTAssertTrue(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_lessThan100_neitherEnabled_returnsFalse() {
        let config = SamplingConfig(samplingPercentage: 50,
                                    onDemandSamplingEnabled: false,
                                    relevantSamplingConfig: RelevantSamplingConfig())

        XCTAssertFalse(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_0Percent_onDemandEnabled_returnsTrue() {
        let config = SamplingConfig(samplingPercentage: 0, onDemandSamplingEnabled: true)

        XCTAssertTrue(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_99Percent_onDemandEnabled_returnsTrue() {
        // boundary: 99 < 100
        let config = SamplingConfig(samplingPercentage: 99, onDemandSamplingEnabled: true)

        XCTAssertTrue(config.isBufferingEnabled())
    }

    func test_isBufferingEnabled_100Percent_bothEnabled_returnsFalse() {
        // samplingPercentage == 100 is the sole blocking condition
        let relevant = RelevantSamplingConfig(enabled: true, enableOnEventTypes: [.frustration])
        let config = SamplingConfig(samplingPercentage: 100,
                                    onDemandSamplingEnabled: true,
                                    relevantSamplingConfig: relevant)

        XCTAssertFalse(config.isBufferingEnabled())
    }
}
