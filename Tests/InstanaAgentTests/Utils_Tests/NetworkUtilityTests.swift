//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
import CoreTelephony
import Network
@testable import InstanaAgent

class NetworkUtilityTests: InstanaTestCase {

    override func setUp() {
        CTTelephonyNetworkInfo.swizzleRadioAccessTechnology()
        super.setUp()
    }

    override func tearDown() {
        CTTelephonyNetworkInfo.swizzleRadioAccessTechnology() // exchange back
        super.tearDown()
    }

    func test_CellularType() {
        AssertEqualAndNotNil(NetworkUtility.CellularType.none.description, "")
        AssertEqualAndNotNil(NetworkUtility.CellularType.twoG.description, "2g")
        AssertEqualAndNotNil(NetworkUtility.CellularType.threeG.description, "3g")
        AssertEqualAndNotNil(NetworkUtility.CellularType.fourG.description, "4g")
        AssertEqualAndNotNil(NetworkUtility.CellularType.fiveG.description, "5g")
        AssertEqualAndNotNil(NetworkUtility.CellularType.unknown.description, "Unknown")
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

    func test_ConnectionType_5G() {
        // Given
        if #available(iOS 14.1, *) {
            CTTelephonyNetworkInfo.stubRadioAccessTechnology = [CTRadioAccessTechnologyNRNSA,
                                                                CTRadioAccessTechnologyNR].randomElement()!
            // Then
            AssertEqualAndNotNil(NetworkUtility.ConnectionType.wifi.cellular, .fiveG)
            AssertEqualAndNotNil(NetworkUtility.ConnectionType.none.description, "None")
            AssertEqualAndNotNil(NetworkUtility.ConnectionType.wifi.description, "Wifi")
            AssertEqualAndNotNil(NetworkUtility.ConnectionType.cellular.description, "5G")
            AssertEqualAndNotNil(NetworkUtility.ConnectionType.undetermined.description, "Unknown")
        }
    }

    func test_unknown() {
        // Given
        CTTelephonyNetworkInfo.stubRadioAccessTechnology = "Some New 10G"

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
