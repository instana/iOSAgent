import Foundation
import XCTest
@testable import InstanaAgent

class InstanaBatteryUtilsTests: InstanaTestCase {

    var batteryUtils: InstanaBatteryUtils!

    override func setUp() {
        UIDevice.swizzleBatteryLevel()
        UIDevice.swizzleBatteryState()
        super.setUp()
    }

    override func tearDown() {
        // exchange back
        UIDevice.swizzleBatteryLevel()
        UIDevice.swizzleBatteryState()
        super.tearDown()
    }

    func test_safeForNetworking_charging_not_enough_level() {
        // Given
        UIDevice.stubBatteryLevel = 0.02
        UIDevice.stubBatteryState = .charging

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == false)
    }

    func test_safeForNetworking_charging_enough_level() {
        // Given
        UIDevice.stubBatteryLevel = 0.021
        UIDevice.stubBatteryState = .charging

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == true)
    }

    func test_safeForNetworking_unplugged_not_enough_level() {
        // Given
        UIDevice.stubBatteryLevel = 0.2
        UIDevice.stubBatteryState = .unplugged

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == false)
    }

    func test_safeForNetworking_unplugged_enough_level() {
        // Given
        UIDevice.stubBatteryLevel = 0.21
        UIDevice.stubBatteryState = .unplugged

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == true)
    }

    func test_safeForNetworking_full() {
        // Given
        UIDevice.stubBatteryLevel = 0.99
        UIDevice.stubBatteryState = .full

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == true)
    }

    func test_safeForNetworking_unknown() {
        // Given
        UIDevice.stubBatteryLevel = 0.99
        UIDevice.stubBatteryState = .unknown

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == false)
    }

    func test_notification_state_change() {
        // Given
        UIDevice.stubBatteryLevel = 0.03
        UIDevice.stubBatteryState = .unplugged

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == false)

        // When
        UIDevice.stubBatteryState = .charging
        NotificationCenter.default.post(name: UIDevice.batteryStateDidChangeNotification, object: nil)

        // Then
        AssertTrue(batteryUtils.safeForNetworking == true)
    }

    func test_notification_level_change() {
        // Given
        UIDevice.stubBatteryLevel = 0.01
        UIDevice.stubBatteryState = .unplugged

        // When
        batteryUtils = InstanaBatteryUtils()

        // Then
        AssertTrue(batteryUtils.safeForNetworking == false)

        // When
        UIDevice.stubBatteryLevel = 0.9
        NotificationCenter.default.post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)

        // Then
        AssertTrue(batteryUtils.safeForNetworking == true)
    }
}
