//
//  Copyright © 2023 IBM Corp. All rights reserved.
//

import XCTest
@testable import InstanaAgent

class DiagnosticBeaconTests: InstanaTestCase {
    func test_DiagnosticBeacon() {
        // Given
        var beacon: CoreBeacon!
        let crashSession = PreviousSession(id: UUID(),
                startTime: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!,
                viewName: "mockViewName",
                carrier: "mockCarrier",
                connectionType: "mockConnectionType",
                userID: "mockUserID",
                userEmail: "mockEmail",
                userName: "mockUserName")

        let crashGroupID = UUID()
        let crashTime = Calendar.current.date(byAdding: .minute, value: -5, to: Date())!.millisecondsSince1970
        let crashBeacon = DiagnosticBeacon(crashSession: crashSession, crashGroupID: crashGroupID,
                crashType: .crash,
                crashTime: crashTime,
                duration: 0,
                crashPayload: "mockCrashPayload",
                formatted: "mockSymbolicated",
                errorType: 1,
                errorMessage: "mockErrorMessage",
                isSymbolicated: true)

        // When
        let mockSession = InstanaSession.mock(configuration: .mock, previousSession: crashSession)
        do {
            beacon = try CoreBeaconFactory(mockSession).map(crashBeacon)
        } catch {
            XCTFail("Could not create Diagnostic CoreBeacon")
        }

        // Then
        AssertEqualAndNotNil(beacon.cti, "\(crashBeacon.crashTime)")
        AssertEqualAndNotNil(beacon.d, "\(crashBeacon.duration)")
        AssertEqualAndNotNil(beacon.ast, crashBeacon.crashPayload)
        AssertEqualAndNotNil(beacon.st, crashBeacon.formatted)
        AssertEqualAndNotNil(beacon.et, "\(crashBeacon.errorType!)")
        AssertEqualAndNotNil(beacon.em, crashBeacon.errorMessage)

        AssertEqualAndNotNil(beacon.sid, crashBeacon.crashSession.id.debugDescription)
        AssertEqualAndNotNil(beacon.v, crashBeacon.crashSession.viewName)
        AssertEqualAndNotNil(beacon.cn, crashBeacon.crashSession.carrier)
        AssertEqualAndNotNil(beacon.ct, crashBeacon.crashSession.connectionType)
        AssertEqualAndNotNil(beacon.ui, crashBeacon.crashSession.userID)
        AssertEqualAndNotNil(beacon.un, crashBeacon.crashSession.userName)
        AssertEqualAndNotNil(beacon.ue, crashBeacon.crashSession.userEmail)

        XCTAssertEqual(beacon.m![crashMetaKeyIsSymbolicated], String(crashBeacon.isSymbolicated))
        XCTAssertEqual(beacon.m![crashMetaKeyInstanaPayloadVersion], currentInstanaCrashPayloadVersion)
        XCTAssertEqual(beacon.m![crashMetaKeyCrashType], "crash")
        XCTAssertEqual(beacon.m![crashMetaKeyGroupID], crashGroupID.uuidString)
        XCTAssertEqual(beacon.m![crashMetaKeySessionID], mockSession.id.uuidString)
        XCTAssertEqual(beacon.m![crashMetaKeyViewName], mockSession.propertyHandler.properties.view)
        XCTAssertEqual(beacon.m!["cn"], InstanaSystemUtils.networkUtility.connectionType.cellular.carrierName)
        XCTAssertEqual(beacon.m!["ct"], InstanaSystemUtils.networkUtility.connectionType.description)
        XCTAssertEqual(beacon.m!["ui"], mockSession.propertyHandler.properties.user?.id)
        XCTAssertEqual(beacon.m!["un"], mockSession.propertyHandler.properties.user?.name)
        XCTAssertEqual(beacon.m!["ue"], mockSession.propertyHandler.properties.user?.email)

        // When
        let sut = beacon.asString
        // When
        let conn = InstanaSystemUtils.networkUtility.connectionType
        let expected = "ab\t\(beacon.ab)\nagv\t\(beacon.agv)\nast\tmockCrashPayload\nav\t\(beacon.av)\nbi\t\(beacon.bi)\nbid\t\(beacon.bid)\ncn\tmockCarrier\nct\tmockConnectionType\ncti\t\(crashTime)\nd\t0\ndma\tApple\ndmo\t\(beacon.dmo)\nem\tmockErrorMessage\net\t1\nk\t\(key)\nm_cn\t\(conn.cellular.carrierName)\nm_ct\t\(conn.description)\nm_id\t\(mockSession.id)\nm_mg\t\(crashGroupID.uuidString)\nm_mt\tcrash\nm_sym\ttrue\nm_ver\t\(currentInstanaCrashPayloadVersion)\nosn\tiOS\nosv\t\(beacon.osv)\np\tiOS\nro\tfalse\nsid\t\(crashSession.id)\nst\tmockSymbolicated\nt\tcrash\nti\t\(crashBeacon.timestamp)\nue\tmockEmail\nuf\tc\nui\tmockUserID\nul\ten\nun\tmockUserName\nv\tmockViewName\nvh\t\(Int(UIScreen.main.bounds.height))\nvw\t\(Int(UIScreen.main.bounds.width))"
        XCTAssertEqual(sut, expected)
    }
}
