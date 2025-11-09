//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class CoreBeaconFactoryTests: InstanaTestCase {

    var randomViewName: String { "Details \((0...9999).randomElement() ?? 1)" }

    func test_undefined_beacon_type() {
        // Given
        let beacon = Beacon()
        let factory = CoreBeaconFactory(InstanaSession.mock)

        // When
        XCTAssertThrowsError(try factory.map(beacon)) {error in
            // Then
            AssertTrue((error as? InstanaError).isUnknownType)
        }
    }

    func test_mobileFeatures_autoCaptureScreenNames_enabled() {
        // Given
        let mfSession = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(),
                                     collectionEnabled: true, autoCaptureScreenNames: true)

        // When
        let mfs = CoreBeaconFactory(mfSession)

        // Then
        AssertEqualAndNotNil(mfs.mobileFeatures!, "c,lm,sn")
    }

    func test_mobileFeatures_autoCaptureScreenNames_disabled() {
        // Given
        let mfSession = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(),
                                     collectionEnabled: true)

        // When
        let mfs = CoreBeaconFactory(mfSession)

        // Then
        AssertEqualAndNotNil(mfs.mobileFeatures!, "c,lm")
    }

    func test_map_beacon() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let viewName = randomViewName
        let beacon = ViewChange(timestamp: timestamp, viewName: viewName)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(beacon) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .viewChange)
        AssertEqualAndNotNil(sut.v, viewName)
        AssertEqualAndNotNil(sut.k, key)
        AssertEqualAndNotNil(sut.ti, "\(beacon.timestamp)")
        AssertEqualAndNotNil(sut.bid, "\(beacon.id)")
        AssertEqualAndNotNil(sut.uf, "c,lm")
        AssertEqualAndNotNil(sut.bi, "\(InstanaSystemUtils.applicationBundleIdentifier)")
        AssertEqualAndNotNil(sut.ul, "en")
        AssertEqualAndNotNil(sut.agv, InstanaSystemUtils.agentVersion)
        AssertEqualAndNotNil(sut.ab, "\(InstanaSystemUtils.applicationBuildNumber)")
        AssertEqualAndNotNil(sut.av, "\(InstanaSystemUtils.applicationVersion)")
        AssertEqualAndNotNil(sut.p, "\(InstanaSystemUtils.systemName)")
        AssertEqualAndNotNil(sut.osn, "\(InstanaSystemUtils.systemName)")
        AssertEqualAndNotNil(sut.osv, "\(InstanaSystemUtils.systemVersion)")
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.dmo, "\(InstanaSystemUtils.deviceModel)")
        AssertEqualAndNotNil(sut.ro, String(InstanaSystemUtils.isDeviceJailbroken))
        AssertEqualAndNotNil(sut.vw, "\(Int(InstanaSystemUtils.screenSize.width))")
        AssertEqualAndNotNil(sut.vh, "\(Int(InstanaSystemUtils.screenSize.height))")
        AssertEqualAndNotNil(sut.cn, "\(InstanaSystemUtils.networkUtility.connectionType.cellular.carrierName)")
        AssertEqualAndNotNil(sut.ct, "\(InstanaSystemUtils.networkUtility.connectionType.description)")

        AssertTrue(sut.ec == nil)
        AssertTrue(sut.et == nil)
        AssertTrue(sut.em == nil)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 24)
    }

    func test_map_beacon_implicit_values() {
        // Given
        let session: InstanaSession = .mock
        let viewName = randomViewName
        session.propertyHandler.properties.view = ViewChange(viewName: viewName)
        let beacon = ViewChange()
        let factory = CoreBeaconFactory(session)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertEqualAndNotNil(sut.v, viewName)
        AssertEqualAndNotNil(sut.ti, "\(beacon.timestamp)")
        AssertEqualAndNotNil(sut.bid, "\(beacon.id)")
    }

    func test_map_http_in_background_background_viewName() {
        // Given
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        let session: InstanaSession = .mock
        let timestamp = Date().millisecondsSince1970
        let beacon = ViewChange(timestamp: timestamp)
        let factory = CoreBeaconFactory(session)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertEqualAndNotNil(sut.v, "Background")
        AssertEqualAndNotNil(sut.cas, "b")
    }

    func test_map_http_in_unknownAppState() {
        // Given
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let session: InstanaSession = .mock
        let factory = CoreBeaconFactory(session)

        let base = "https://www.google.com/"
        let suffix = ".html"
        let path = (0..<HTTPBeacon.maxLengthURL - base.count - suffix.count).map {_ in "A"}.joined()
        let url = URL(string: base + path + suffix)

        // When
        let beacon = HTTPBeacon(method: "GET", url: url!, responseCode: 200)
        let sut = try! factory.map(beacon)

        // Then
        AssertEqualAndNotNil(sut.cas, "u")
    }

    func test_map_customBeacon() {
        // Given
        let timestamp = Date().millisecondsSince1970
        let viewName = randomViewName
        let eventType = "test.event.type"
        let beacon = CustomBeacon(timestamp: timestamp, name: viewName, eventType: eventType)
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        let internalMetaEventType = sut.im![internalMetaDataKeyCustom_eventType]
        AssertEqualAndNotNil(internalMetaEventType, eventType)
    }

    func test_map_ViewChangeBeacon_autoScreenNameCapture1() {
        // Given
        let beacon = ViewChange(viewName: "testViewName",
                                accessibilityLabel: "testAccessibilityLabelValue",
                                navigationItemTitle: "testNavigationItemTitle",
                                className: "testClassName", isSwiftUI: true)
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.im!["view.clsName"] == "testClassName")
        AssertTrue(sut.im!["view.accLabel"] == "testAccessibilityLabelValue")
    }

    func test_map_ViewChangeBeacon_autoScreenNameCapture2() {
        // Given
        let beacon = ViewChange(viewName: "testViewName",
                                navigationItemTitle: "testNavigationItemTitle",
                                className: "testClassName", isSwiftUI: true,
                                viewInternalCPMetaMap: ["testKey": "testValue"])
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.im!["view.clsName"] == "testClassName")
        AssertTrue(sut.im!["view.navItemTitle"] == "testNavigationItemTitle")
        AssertTrue(sut.im!["testKey"] == "testValue")
    }

    func test_map_droppedBeacons() {
        // Given
        let beaconsMap: [String: String] = ["droppedBeaconKey": "droppedBeaconValue"]
        let beacon = DroppedBeacons(beaconsMap: beaconsMap,
                                    timestamp: Date().millisecondsSince1970,
                                    viewName: "TestViewName")
        let factory = CoreBeaconFactory(session)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.im!["droppedBeaconKey"] == "droppedBeaconValue")
    }

    func test_map_performanceBeacon_appLaunch_cold() {
        // Given
        let beacon = PerfAppLaunchBeacon(appColdStartTime: 12345)
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.acs == "12345")
    }

    func test_map_performanceBeacon_appLaunch_warm() {
        // Given
        let beacon = PerfAppLaunchBeacon(appWarmStartTime: 678)
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.aws == "678")
    }

    func test_map_performanceBeacon_appLaunch_hot() {
        // Given
        let beacon = PerfAppLaunchBeacon(appHotStartTime: 9)
        let factory = CoreBeaconFactory(.mock)

        // When
        let sut = try! factory.map(beacon)

        // Then
        AssertTrue(sut.ahs == "9")
    }

    func test_mobileFeatures() {
        // Given
        let config = InstanaConfiguration.default(key: "key", reportingURL: URL(string: "http://localhost:3000")!,
                enableCrashReporting: true, perfConfig: InstanaPerformanceConfig(enableAppStartTimeReport: true,
                enableAnrReport: true, anrThreshold: 4.0, enableLowMemoryReport: true),
                enableW3CHeaders: true, deleteOldBeacons: false, maxBeaconResendTries: 999)
        let session = InstanaSession(configuration: config, propertyHandler: InstanaPropertyHandler(),
                                     collectionEnabled: true, autoCaptureScreenNames: true, debugAllScreenNames: true,
                                     dropBeaconReporting: true)
        // When
        let factory = CoreBeaconFactory(session)

        // Then
        AssertTrue(factory.mobileFeatures! == "c,lm,anr,sn,db,ot")
    }

    func test_create_from_string() {
        // Given
        let httpBody = "ab\t15702\nav\tunknown-version\nbid\tB5FAF31C-FE37-482E-97F2-20D49C506586\nbt\tBackendTracingID\nbi\tcom.apple.dt.xctest.tool\ncn\tNone\nct\tWifi\nd\t1578569955952\ndma\tApple\ndmo\tx86_64\nec\t1\nem\tA client or server connection was severed in the middle of an in-progress load.\net\tNetwork Connection Lost\nhm\tPOST\nhs\t200\nhu\thttps://www.example.com\nk\tKEY\np\tiOS\nosn\tiOS\nosv\t13.3\nagv\t1.0.4\nro\t\(String(InstanaSystemUtils.isDeviceJailbroken))\nsid\t70BED140-D947-4EC7-ADE9-8F1F7C6955D0\nusi\t70BED140-D947-4EC7-ADE9-8F1F7C6955D0\nt\thttpRequest\nti\t1578569955952\nuf\tc\nul\ten\nvh\t1792\nvw\t828\nm_meta1\tV\nm_meta2\tL\nh_X_K\tV"

        // When
        let sut: CoreBeacon
        do {
            sut = try CoreBeacon.create(from: httpBody)
        } catch {
            XCTFail("Must not be nil \(error)")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, BeaconType.httpRequest)
        AssertEqualAndNotNil(sut.ab, "15702")
        AssertEqualAndNotNil(sut.av, "unknown-version")
        AssertEqualAndNotNil(sut.bid, "B5FAF31C-FE37-482E-97F2-20D49C506586")
        AssertEqualAndNotNil(sut.bt, "BackendTracingID")
        AssertEqualAndNotNil(sut.bi, "com.apple.dt.xctest.tool")
        AssertEqualAndNotNil(sut.cn, "None")
        AssertEqualAndNotNil(sut.ct, "Wifi")
        AssertEqualAndNotNil(sut.d, "1578569955952")
        AssertEqualAndNotNil(sut.dma, "Apple")
        AssertEqualAndNotNil(sut.dmo, "x86_64")
        AssertEqualAndNotNil(sut.ec, "1")
        AssertEqualAndNotNil(sut.et, "Network Connection Lost")
        AssertEqualAndNotNil(sut.em, "A client or server connection was severed in the middle of an in-progress load.")
        AssertEqualAndNotNil(sut.hm, "POST")
        AssertEqualAndNotNil(sut.hs, "200")
        AssertEqualAndNotNil(sut.hu, "https://www.example.com")
        AssertEqualAndNotNil(sut.k, "KEY")
        AssertEqualAndNotNil(sut.p, "iOS")
        AssertEqualAndNotNil(sut.osn, "iOS")
        AssertEqualAndNotNil(sut.osv, "13.3")
        AssertEqualAndNotNil(sut.agv, "1.0.4")
        AssertEqualAndNotNil(sut.ro, String(InstanaSystemUtils.isDeviceJailbroken))
        AssertEqualAndNotNil(sut.sid, "70BED140-D947-4EC7-ADE9-8F1F7C6955D0")
        AssertEqualAndNotNil(sut.usi, "70BED140-D947-4EC7-ADE9-8F1F7C6955D0")
        AssertEqualAndNotNil(sut.ti, "1578569955952")
        AssertEqualAndNotNil(sut.uf, mobileFeatureCrash)
        AssertEqualAndNotNil(sut.ul, "en")
        AssertEqualAndNotNil(sut.vh, "1792")
        AssertEqualAndNotNil(sut.vw, "828")
        AssertEqualAndNotNil(sut.m, ["meta1": "V", "meta2": "L"])
        AssertEqualAndNotNil(sut.h, ["X_K": "V"])

        let mirror = Mirror(reflecting: sut)
        AssertEqualAndNotZero(mirror.nonNilChildren.count, 32)
    }

    /// All other beacon mapping will be tested in the 'Beacon Types' Tests (-> HTTPBeaconTests or CustomBeaconTests)
}
