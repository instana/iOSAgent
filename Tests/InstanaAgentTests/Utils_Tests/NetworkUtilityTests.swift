import Foundation
import XCTest
import CoreTelephony
import Network
@testable import InstanaAgent

extension CTTelephonyNetworkInfo {
    static var stubRadioAccessTechnology: String? = "Some"
    @objc var stubbedRadioAccessTechnology: String? { CTTelephonyNetworkInfo.stubRadioAccessTechnology }
}

class NetworkUtilityTests: XCTestCase {

    override func setUp() {
        swizzle()
        super.setUp()
    }

    override func tearDown() {
        swizzle() // exchange back
        super.tearDown()
    }

    func swizzle() {
        let originalMethod = class_getInstanceMethod(CTTelephonyNetworkInfo.self, #selector(getter: CTTelephonyNetworkInfo.currentRadioAccessTechnology))
        let swizzledMethod = class_getInstanceMethod(CTTelephonyNetworkInfo.self, #selector(getter: CTTelephonyNetworkInfo.stubbedRadioAccessTechnology))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    func test_CellularType() {
        AssertEqualAndNotNil(NetworkUtility.CellularType.none.rawValue, "None")
        AssertEqualAndNotNil(NetworkUtility.CellularType.twoG.rawValue, "2G")
        AssertEqualAndNotNil(NetworkUtility.CellularType.threeG.rawValue, "3G")
        AssertEqualAndNotNil(NetworkUtility.CellularType.fourG.rawValue, "4G")
        AssertEqualAndNotNil(NetworkUtility.CellularType.unknown.rawValue, "Unknown")
    }

    func test_GPRS() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyGPRS

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .twoG)
    }

    func test_Edge() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyEdge

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .twoG)
    }

    func test_CDMA1x() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyCDMA1x

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .twoG)
    }

    func test_WCDMA() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyWCDMA

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_HSDPA() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyHSDPA

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_HSUPA() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyHSUPA

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_CDMAEVDORev0() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyCDMAEVDORev0

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_CDMAEVDORevA() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyCDMAEVDORevA

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_CDMAEVDORevB() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyCDMAEVDORevB

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_HRPD() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyeHRPD

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .threeG)
    }

    func test_LTE() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyLTE

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .fourG)
    }

    func test_unknown() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = "Some New 5G"

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .unknown)
    }

    func test_none() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = nil

        // Then
        AssertEqualAndNotNil(NetworkUtility.CellularType.current, .none)
    }

    func test_ConnectionType() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = CTRadioAccessTechnologyLTE

        // Then
        AssertEqualAndNotNil(NetworkUtility.ConnectionType.wifi.cellular, .fourG)
        AssertEqualAndNotNil(NetworkUtility.ConnectionType.none.description, "None")
        AssertEqualAndNotNil(NetworkUtility.ConnectionType.wifi.description, "Wifi")
        AssertEqualAndNotNil(NetworkUtility.ConnectionType.cellular.description, "4G")
        AssertEqualAndNotNil(NetworkUtility.ConnectionType.undetermined.description, "Unknown")
    }
}
