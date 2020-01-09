import Foundation
import XCTest
@testable import InstanaAgent

extension UIDevice {
    static var stubBatteryLevel: Float = 0.0
    @objc var stubbedBatteryLevel: Float { UIDevice.stubBatteryLevel }

    static var stubBatteryState: BatteryState = .unknown
    @objc var stubbedBatteryState: BatteryState { UIDevice.stubBatteryState }
}

class InstanaBatteryUtilsTests: XCTestCase {

    var batteryUtils: InstanaBatteryUtils!

    override func setUp() {
        swizzleLevel()
        swizzleState()
        super.setUp()
    }

    override func tearDown() {
        swizzleLevel() // exchange back
        swizzleState()
        super.tearDown()
    }

    func swizzleLevel() {
        let originalMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.batteryLevel))
        let swizzledMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.stubbedBatteryLevel))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    func swizzleState() {
        let originalMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.batteryState))
        let swizzledMethod = class_getInstanceMethod(UIDevice.self, #selector(getter: UIDevice.stubbedBatteryState))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
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
