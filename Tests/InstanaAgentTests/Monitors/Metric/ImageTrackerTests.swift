//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import Foundation
#if canImport(MetricKit)
import MetricKit
#endif
import XCTest
@testable import ImageTracker
@testable import InstanaAgent


class ImageTrackerTests: InstanaTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_startTrackingDyldImages() {
        // test 1, start tracking
        // When
        ImageTracker.startTrackingDyldImages()

        // Then
        // binaryImagesDict must have been created
        XCTAssertNotNil(ImageTracker.binaryImagesDict)

        // test 2, pause tracking
        // When
        ImageTracker.pauseTracking = true

        // Then
        XCTAssertTrue(ImageTracker.pauseTracking)

        // test 3, let image populate
        Thread.sleep(forTimeInterval: 0.1)
        ImageTracker.pauseTracking = false
    }

    func test_pauseTracking() {
        // Given
        XCTAssertFalse(ImageTracker.pauseTracking)

        // When
        ImageTracker.pauseTracking = true

        // Then
        XCTAssertTrue(ImageTracker.pauseTracking)

        // Restore to default so as not to affect other test cases
        ImageTracker.pauseTracking = false
    }

    func test_getArchitecture() {
        // Given
        var arch: String?
        let imageDetail = ImageDetail()

        // test 1
        // When
        imageDetail.cputype = 12 // CPU_TYPE_ARM
        imageDetail.cpusubtype = 11 // CPU_SUBTYPE_ARM_V7S
        arch = imageDetail.getArchitecture()
        // Then
        XCTAssertEqual(arch, "armv7s")

        // test 2
        imageDetail.cputype = (12 | 16777216) // CPU_TYPE_ARM | CPU_ARCH_ABI64
        imageDetail.cpusubtype = 2 // CPU_SUBTYPE_ARM64E
        arch = imageDetail.getArchitecture()
        // Then
        XCTAssertEqual(arch, "arm64e")

        // test 3
        imageDetail.cputype = 16777228 // CPU_TYPE_ARM | CPU_ARCH_ABI64
        imageDetail.cpusubtype = 0 // CPU_SUBTYPE_ARM64_ALL
        arch = imageDetail.getArchitecture()
        // Then
        XCTAssertEqual(arch, "arm64")

        // test 4
        imageDetail.cputype = 12 // CPU_TYPE_ARM
        imageDetail.cpusubtype = 12 // CPU_SUBTYPE_ARM_V7K
        arch = imageDetail.getArchitecture()
        // Then
        XCTAssertEqual(arch, "armv7k")

        // test 5, other
        imageDetail.cputype = 100
        imageDetail.cpusubtype = 200
        arch = imageDetail.getArchitecture()
        // Then
        XCTAssertNil(arch)
    }
}
