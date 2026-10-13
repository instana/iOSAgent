
import XCTest
@testable import InstanaAgent
@_spi(Internal) import InstanaAgent

class ImageBeaconTests: InstanaTestCase {

    func test_init_rctDefault() {
        // Given
        let id = "16984318567976187082"
        let imageData: Data? = nil
        let meta: [String: String] = ["a":"b", "c":"d", "imageId": id]
        let timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970

        // When
        let sut = ImageBeacon(image: imageData, meta: meta, timestamp: timestamp)

        // Then
        XCTAssertEqual(imageData, sut.img)
        XCTAssertEqual(meta, sut.meta)
        XCTAssertEqual(timestamp, sut.ti)
        XCTAssertEqual(nil, sut.rct)
    }

    func test_init_rctPassed() {
        // Given
        let id = "13422339073088273168"
        let imageData: Data? = "Fake Image Data".data(using: .utf8)
        let meta: [String: String] = ["e":"f", "g":"h", "imageId": id]
        let timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970
        let rctVal = 3

        // When
        let sut = ImageBeacon(image: imageData, meta: meta, timestamp: timestamp, retryCount: rctVal)

        // Then
        XCTAssertEqual(imageData, sut.img)
        XCTAssertEqual(meta, sut.meta)
        XCTAssertEqual(timestamp, sut.ti)
        XCTAssertEqual(rctVal, sut.rct)
    }

    func test_increaseRetryCount() {
        // Given
        var imageBeacon = createTestImageBeacon()

        // Then 1
        XCTAssertEqual(nil, imageBeacon.rct)

        // Then 1
        imageBeacon.increaseRetryCount()
        XCTAssertEqual(1, imageBeacon.rct)

        // Then 3
        imageBeacon.increaseRetryCount()
        XCTAssertEqual(2, imageBeacon.rct)
    }

    func test_equal_sameBeacon() {
        // Given
        let beacon1 = createTestImageBeacon()
        let beacon2 = beacon1

        // Then
        XCTAssertEqual(beacon1, beacon2)
    }

    func test_equal_sameBidDifferentElse() {
        // Given
        let bid = Beacon.generateUniqueIdImpl()
        let beacon1 = createTestImageBeacon(bid: bid, imageData: "Test Image Data".data(using: .utf8))
        let beacon2 = createTestImageBeacon(bid: bid, retryCount: 2)

        // When
        XCTAssertEqual(beacon1, beacon2)
    }

    func test_not_equal() {
        // Given
        let beacon1 = createTestImageBeacon(ti: Date().millisecondsSince1970)
        let beacon2 = createTestImageBeacon(ti: Date().millisecondsSince1970+10)

        // Then
        XCTAssertNotEqual(beacon1, beacon2)
    }


    func test_hash_equalValuesHaveEqualHash() {
        // Given
        let time: Instana.Types.Milliseconds = 12345678
        // 2 beacons only timestamp identical, everything else different
        let iBeacon1 = createTestImageBeacon(bid: "testBid1", retryCount: 2, ti: time)
        let iBeacon2 = createTestImageBeacon(bid: "testBid2", imageData: Data([0x01]), retryCount: 5, meta: ["k": "v"], ti: time)

        // When
        var hasher1 = Hasher()
        iBeacon1.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        iBeacon2.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        // Then
        XCTAssertEqual(hash1, hash2)
    }

    func test_hash_differentTimestampsHaveDifferentHash() {
        // Given
        let imageData: Data? = Data([0x01])
        let meta: [String: String] = ["a":"b", "c":"d"]
        let timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970

        let bid1 = Beacon.generateUniqueIdImpl()

        // When
        // 2 beacons only timestamp different, everything else identical
        let iBeacon1 = createTestImageBeacon(bid: bid1, imageData: imageData, meta: meta, ti: timestamp)
        let iBeacon2 = createTestImageBeacon(bid: bid1, imageData: imageData, meta: meta, ti: timestamp-20)

        // Then
        var hasher1 = Hasher()
        iBeacon1.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        iBeacon2.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        XCTAssertNotEqual(hash1, hash2)
    }


    // MARK: Test In-Flight Flag Operations

    func test_inflight_flag_initially_nil() {
        // Given / When
        let beacon = createTestImageBeacon()

        // Then
        XCTAssertNil(beacon.ifl)
    }

    func test_markInFlight() {
        // Given
        var beacon = createTestImageBeacon()

        // When
        beacon.markInFlight()

        // Then
        XCTAssertEqual(beacon.ifl, true)
    }

    func test_clearInFlight() {
        // Given
        var beacon = createTestImageBeacon()
        beacon.markInFlight()
        XCTAssertEqual(beacon.ifl, true)

        // When
        beacon.clearInFlight()

        // Then
        XCTAssertNil(beacon.ifl)
    }

    func test_mark_and_clear_inflight_multiple_times() {
        // Given
        var beacon = createTestImageBeacon()

        // When / Then
        beacon.markInFlight()
        XCTAssertEqual(beacon.ifl, true)

        beacon.clearInFlight()
        XCTAssertNil(beacon.ifl)

        beacon.markInFlight()
        XCTAssertEqual(beacon.ifl, true)

        beacon.clearInFlight()
        XCTAssertNil(beacon.ifl)
    }

    func createTestImageBeacon(bid: String? = nil, imageData: Data? = nil, retryCount: Int? = nil,
                               meta: [String: String]? = nil, ti: Instana.Types.Milliseconds? = nil) -> ImageBeacon {
        let bid = bid ?? "13422339073088273168"
        let meta = meta ?? ["m":"n", "s":"t", "imageId":bid]
        let timestamp = ti ?? Date().millisecondsSince1970

        return ImageBeacon(image: imageData, meta: meta, timestamp: timestamp, retryCount: retryCount)
    }
}

