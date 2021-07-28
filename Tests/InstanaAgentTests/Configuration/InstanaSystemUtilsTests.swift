import XCTest
@testable import InstanaAgent

class InstanaSystemUtilsTests: InstanaTestCase {

    func test_AgentVersion() {
        // Then
        AssertTrue(InstanaSystemUtils.agentVersion == "1.1.17")
    }

    func test_systemVersion() {
        AssertEqualAndNotNil(InstanaSystemUtils.systemVersion, expectedSystemVersion)
    }

    func test_systemName() {
        AssertEqualAndNotNil(InstanaSystemUtils.systemName, expectedSystemName)
    }

    var expectedSystemVersion: String {
        "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
    }

    var expectedSystemName: String {
        let macOS = "macOS"
        if #available(iOS 13.0, *) {
            if ProcessInfo.processInfo.isMacCatalystApp {
                return macOS
            }
        }
        if #available(iOS 14.0, *) {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                return macOS
            }
        }
        #if os(macOS)
            return macOS
        #elseif os(tvOS) || os(watchOS) || os(iOS)
            return UIDevice.current.systemName
        #endif
    }
}
