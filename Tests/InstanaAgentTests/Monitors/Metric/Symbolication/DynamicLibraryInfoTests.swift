//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation
import XCTest
@testable import InstanaAgent

class DynamicLibraryInfoTests: InstanaTestCase {

    // MARK: - init (imageInMemory: false)

    func test_init_notInMemory_setsFieldsFromArguments() {
        // Given
        let path = "/usr/lib/libfoo.dylib"
        let address: UInt = 0x1000
        let arch = "arm64"
        let size: UInt = 4096

        // When
        let info = DynamicLibraryInfo(imageInMemory: false,
                                      address: address,
                                      architecture: arch,
                                      size: size,
                                      path: path)

        // Then
        XCTAssertNotNil(info)
        XCTAssertFalse(info!.imageInMemory)
        XCTAssertEqual(info!.address, address)
        XCTAssertEqual(info!.architecture, arch)
        XCTAssertEqual(info!.size, size)
        XCTAssertEqual(info!.path, path)
        XCTAssertNil(info!.symbolName)
        XCTAssertEqual(info!.symbolAddress, 0)
    }

    func test_init_notInMemory_nilPathAndArchitecture() {
        // When
        let info = DynamicLibraryInfo(imageInMemory: false,
                                      address: 0x2000,
                                      architecture: nil,
                                      size: 512,
                                      path: nil)

        // Then
        XCTAssertNotNil(info)
        XCTAssertNil(info!.architecture)
        XCTAssertNil(info!.path)
        XCTAssertNil(info!.symbolName)
        XCTAssertEqual(info!.symbolAddress, 0)
    }

    // MARK: - init (imageInMemory: true)

    func test_init_inMemory_withValidAddress_succeeds() {
        // Use the address of a known C function that is always loaded in the
        // test process so dladdr() is guaranteed to succeed.
        let ptr = unsafeBitCast(dladdr as @convention(c) (UnsafeRawPointer?, UnsafeMutablePointer<Dl_info>?) -> Int32, to: UnsafeRawPointer.self)
        let address = UInt(bitPattern: ptr)

        // When
        let info = DynamicLibraryInfo(imageInMemory: true,
                                      address: address,
                                      architecture: "arm64",
                                      size: 0,
                                      path: nil)

        // Then — dladdr succeeds for a real in-process symbol
        XCTAssertNotNil(info)
        XCTAssertTrue(info!.imageInMemory)
        XCTAssertEqual(info!.address, address)
        // path comes from dladdr (dli_fname), not from the argument
        XCTAssertNotNil(info!.path)
    }

    func test_init_inMemory_withInvalidAddress_returnsNil() {
        // Address 0 is never a valid mapped address, so dladdr returns 0 → init returns nil.
        let info = DynamicLibraryInfo(imageInMemory: true,
                                      address: 0,
                                      architecture: nil,
                                      size: 0,
                                      path: nil)

        // Then
        XCTAssertNil(info)
    }

    // MARK: - symbolInfo

    func test_symbolInfo_notInMemory_returnsNil() {
        // Given
        let info = DynamicLibraryInfo(imageInMemory: false,
                                      address: 0x1000,
                                      architecture: nil,
                                      size: 0,
                                      path: nil)!

        // When / Then
        XCTAssertNil(info.symbolInfo)
    }

    func test_symbolInfo_inMemory_returnsSymbolInfoWithOffset() {
        // Given – use a live address so dladdr succeeds and symbolAddress is populated
        let ptr = unsafeBitCast(dladdr as @convention(c) (UnsafeRawPointer?, UnsafeMutablePointer<Dl_info>?) -> Int32, to: UnsafeRawPointer.self)
        let address = UInt(bitPattern: ptr)
        guard let info = DynamicLibraryInfo(imageInMemory: true,
                                             address: address,
                                             architecture: "arm64",
                                             size: 0,
                                             path: nil) else {
            XCTFail("Expected DynamicLibraryInfo to be non-nil for a valid in-process address")
            return
        }

        // When
        let symbolInfo = info.symbolInfo

        // Then
        XCTAssertNotNil(symbolInfo)
        // offset = address - symbolAddress; both values come from dladdr, so offset >= 0
        if let si = symbolInfo {
            XCTAssertGreaterThanOrEqual(si.offset ?? 0, 0)
        }
    }

    func test_symbolInfo_inMemory_symbolNameStoredCorrectly() {
        // Given
        let ptr = unsafeBitCast(dladdr as @convention(c) (UnsafeRawPointer?, UnsafeMutablePointer<Dl_info>?) -> Int32, to: UnsafeRawPointer.self)
        let address = UInt(bitPattern: ptr)
        guard var info = DynamicLibraryInfo(imageInMemory: true,
                                             address: address,
                                             architecture: nil,
                                             size: 0,
                                             path: nil) else {
            XCTFail("Expected DynamicLibraryInfo to be non-nil for a valid in-process address")
            return
        }

        // When – override symbolName and verify symbolInfo reflects it
        let customSymbol = "customSymbol"
        info.symbolName = customSymbol
        let symbolInfo = info.symbolInfo

        // Then
        XCTAssertEqual(symbolInfo?.symbol, customSymbol)
    }
}
