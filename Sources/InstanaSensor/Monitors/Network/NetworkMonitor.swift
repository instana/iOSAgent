//  Created by Nikola Lajic on 3/26/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import Network
import CoreTelephony

class NetworkMonitor {
    private(set) var connectionType: ConnectionType = .none
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var connectionUpdateHandler: (ConnectionType) -> Void = {_ in }
    @available(iOS 12.0, *)
    private lazy var monitor: NWPathMonitor = {
        let monitor = NWPathMonitor()
        if ProcessInfo.processInfo.isRunningTests {
            self.connectionType = .wifi
            return monitor
        }
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard path.status == .satisfied else {
                    self.connectionType = .none
                    return
                }
                if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        return monitor
    }()

    init() {
        if #available(iOS 12.0, *) {
            monitor.start(queue: queue)
        }
    }
    
    deinit {
        if #available(iOS 12.0, *) {
            monitor.cancel()
        }
    }
}

extension NetworkMonitor {
    enum CellularType: String {
        case none, twoG, threeG, fourG, unknown
        var rawValue: String {
            switch self {
            case .none: return "None"
            case .twoG: return "2G"
            case .threeG: return "3G"
            case .fourG: return "4G"
            case .unknown: return "Unknown"
            }
        }

        var carrierName: String {
            if ProcessInfo.processInfo.isRunningTests {
                return "None"
            }
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            return carrier?.carrierName ?? ""
        }

        static var current: CellularType {
            if ProcessInfo.processInfo.isRunningTests {
                return .none
            }
            switch CTTelephonyNetworkInfo().currentRadioAccessTechnology {
            case CTRadioAccessTechnologyGPRS?, CTRadioAccessTechnologyEdge?, CTRadioAccessTechnologyCDMA1x?:
                return .twoG
            case CTRadioAccessTechnologyWCDMA?, CTRadioAccessTechnologyHSDPA?, CTRadioAccessTechnologyHSUPA?, CTRadioAccessTechnologyCDMAEVDORev0?, CTRadioAccessTechnologyCDMAEVDORevA?, CTRadioAccessTechnologyCDMAEVDORevB?, CTRadioAccessTechnologyeHRPD?:
                return .threeG
            case CTRadioAccessTechnologyLTE?:
                return .fourG
            default:
                return .unknown
            }
        }
    }

    enum ConnectionType: String, CustomStringConvertible {
        case none, wifi, cellular, unknown

        var cellular: CellularType { CellularType.current }

        var description: String {
            switch self {
            case .none: return "None"
            case .wifi: return "Wifi"
            case .cellular: return CellularType.current.rawValue
            case .unknown: return "Unknown"
            }
        }
    }
}
