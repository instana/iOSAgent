//
//  Copyright © 2024 IBM Corp. All rights reserved.
//

import Foundation

///
/// A handler for beacons that were dropped because the maximum beacon send limit was reached.
/// This will sample the dropped beacons and attempt to resend them as a custom event, once the
/// limit is no longer exceeded.
///
public class DropBeaconHandler {
    var httpUniqueMap: [String: DropBeacon]
    var viewUniqueMap: [String: DropBeacon]
    var customUniqueMap: [String: DropBeacon]
    var MIN_BEACONS_REQUIRED = 2
    let SAMPLING_BEACON_LIMIT = 5
    var droppingStartTime: Instana.Types.Milliseconds
    var droppingStartView: String?

    init() {
        httpUniqueMap = [String: DropBeacon]()
        viewUniqueMap = [String: DropBeacon]()
        customUniqueMap = [String: DropBeacon]()
        droppingStartTime = 0
        droppingStartView = nil
    }

    func addBeaconToDropHandler(beacon: Beacon) {
        guard let extractedBeacon = beacon.extractDropBeaconValues() else {
            return
        }

        if droppingStartTime == 0 {
            droppingStartTime = Date().millisecondsSince1970
        }

        let key = extractedBeacon.getKey()
        if extractedBeacon is HTTPDropBeacon {
            saveDroppedBeacons(dropBeacon: extractedBeacon, key: key, uniqueMap: &httpUniqueMap)
        } else if extractedBeacon is ViewDropBeacon {
            saveDroppedBeacons(dropBeacon: extractedBeacon, key: key, uniqueMap: &viewUniqueMap)
        } else if extractedBeacon is CustomEventDropBeacon {
            saveDroppedBeacons(dropBeacon: extractedBeacon, key: key, uniqueMap: &customUniqueMap)
        }

        if droppingStartView == nil {
            droppingStartView = beacon.viewName
        }
    }

    func mergeDroppedBeacons() -> CustomBeacon? {
        if droppingStartTime == 0 {
            // no dropped beacons
            return nil
        }

        var totalDropBeaconCount = 0
        var mergedBeaconsMap = [String: String]()
        totalDropBeaconCount += mergeDroppedBeacons(uniqueMap: httpUniqueMap,
                                                    keyPrefix: "HTTP", mergedBeacons: &mergedBeaconsMap)
        totalDropBeaconCount += mergeDroppedBeacons(uniqueMap: viewUniqueMap,
                                                    keyPrefix: "VIEW", mergedBeacons: &mergedBeaconsMap)
        totalDropBeaconCount += mergeDroppedBeacons(uniqueMap: customUniqueMap,
                                                    keyPrefix: "CUSTOM_EVENT", mergedBeacons: &mergedBeaconsMap)

        guard totalDropBeaconCount > 0 else {
            reset() // Throw away accumulated dropped beacons if there are not many
            return nil
        }

        let mergedBeacons = CustomBeacon(timestamp: droppingStartTime,
                                         name: "INSTANA_DROPPED_BEACON_SAMPLE",
                                         metaData: mergedBeaconsMap,
                                         viewName: droppingStartView,
                                         customMetric: Double(totalDropBeaconCount),
                                         eventType: "beacon-drop")

        reset() // Prepare for next round, might throw away some unsent beacons
        return mergedBeacons
    }

    private func reset() {
        droppingStartTime = 0
        droppingStartView = nil
        httpUniqueMap = [String: DropBeacon]()
        viewUniqueMap = [String: DropBeacon]()
        customUniqueMap = [String: DropBeacon]()
    }

    private func saveDroppedBeacons(dropBeacon: DropBeacon, key: String, uniqueMap: inout [String: DropBeacon]) {
        if let existingBeacon = uniqueMap[key] {
            existingBeacon.count += 1
            if dropBeacon.timeMin < existingBeacon.timeMin {
                existingBeacon.timeMin = dropBeacon.timeMin
            }
            if dropBeacon.timeMax > existingBeacon.timeMax {
                existingBeacon.timeMax = dropBeacon.timeMax
            }
        } else {
            uniqueMap[key] = dropBeacon
        }
    }

    private func mergeDroppedBeacons(uniqueMap: [String: DropBeacon], keyPrefix: String,
                                     mergedBeacons: inout [String: String]) -> Int {
        let totalDropBeaconCount = uniqueMap.reduce(into: 0) { result, entry in
            result += entry.value.count
        }

        if totalDropBeaconCount > MIN_BEACONS_REQUIRED {
            // Though only maximum SAMPLING_BEACON_LIMIT beacons are collected,
            // totalDropBeaconCount includes the not sampled beacons.
            let descendingDropBeacons = uniqueMap.sorted { $0.value.count > $1.value.count }.prefix(SAMPLING_BEACON_LIMIT)
            for (_, entryValue) in descendingDropBeacons {
                let key = generateKey(prefix: keyPrefix)
                mergedBeacons[key] = entryValue.toString()
            }
            return totalDropBeaconCount
        }
        return 0
    }

    private func generateKey(prefix: String) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomStr = String((0 ..< 6).map { _ in chars.randomElement()! })
        return "\(prefix)-\(randomStr)"
    }
}
