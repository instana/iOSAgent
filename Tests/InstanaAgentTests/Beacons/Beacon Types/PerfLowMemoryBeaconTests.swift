import XCTest
@testable import InstanaAgent

class PerfLowMemoryBeaconTests: InstanaTestCase {
    func test_lowMemory_init() {
        // Given
        let perf = PerfLowMemoryBeacon(usedMemory: 20, availableMemory: 60, maximumMemory: 32686)
        let factory = CoreBeaconFactory(.mock)

        // When
        guard let sut = try? factory.map(perf) else {
            XCTFail("Could not map Beacon to CoreBeacon")
            return
        }

        // Then
        AssertEqualAndNotNil(sut.t, .perf)
        AssertEqualAndNotNil(sut.pst, "oom")
        AssertTrue(sut.ec == nil)
        AssertTrue(sut.et == nil)
        AssertTrue(sut.em == nil)

        let values = Mirror(reflecting: sut).nonNilChildren
        XCTAssertEqual(values.count, 27)
    }

    func test_asString() {
        // Given
        let perf = PerfLowMemoryBeacon(usedMemory: 20, availableMemory: 60, maximumMemory: 32686)
        var beacon: CoreBeacon!
        let mockedInstanaSession = InstanaSession.mock(configuration: .mock)
        do {
            beacon = try CoreBeaconFactory(mockedInstanaSession).map(perf)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }

        // When
        let sut = beacon.asString

        // When
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\namb\t60\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncas\tf\ncn\t\(beacon.cn ?? "")\nct\t\(beacon.ct ?? "")\ndma\tApple\ndmo\t\(beacon.dmo)\nk\t\(key)\nmmb\t32686\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\npst\toom\nro\t\(String(InstanaSystemUtils.isDeviceJailbroken))\nsid\t\(beacon.sid)\nt\tperf\nti\t\(perf.timestamp)\nuf\tc,lm\nul\ten\numb\t20\nusi\t\(mockedInstanaSession.usi!.uuidString)\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        XCTAssertEqual(sut, expected)
    }

    func test_asJSON() {
        // Given
        let perf = PerfLowMemoryBeacon(usedMemory: 20, availableMemory: 60, maximumMemory: 32686)

        // When
        var beacon: CoreBeacon!
        do {
            beacon = try CoreBeaconFactory(.mock(configuration: .mock)).map(perf)
        } catch {
            XCTFail("Could not create CoreBeacon")
        }
        let mirror = Mirror(reflecting: beacon!)
        guard let sut = beacon.asJSON else { XCTFail("Cannot convert Beacon to JSON"); return }

        // Then
        AssertTrue(sut.count > 0)
        AssertTrue(sut.count == mirror.nonNilChildren.count)

        mirror.nonNilChildren.forEach { child in
            let value = child.value as AnyObject
            AssertEqualAndNotNil(sut[child.label] as? String, value.description, "Values for \(child.0) must be same")
        }
    }
}
