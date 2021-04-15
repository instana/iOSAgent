//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import CoreTelephony
import Foundation
import Network

class NetworkUtility {
    var connectionType: ConnectionType = .undetermined {
        didSet {
            if oldValue != .undetermined {
                connectionUpdateHandler(connectionType)
            }
        }
    }

    var connectionUpdateHandler: (ConnectionType) -> Void = { _ in }
    private var reachability: Reachability?
    static let shared = NetworkUtility()

    init(observeNetworkChanges: Bool = true) {
        if #available(iOS 12.0, *) {
            let nwPathMonitor = NWPathMonitor()
            nwPathMonitor.pathUpdateHandler = { path in
                if path.usesInterfaceType(.wifi) {
                    self.update(.wifi)
                } else if path.usesInterfaceType(.cellular) {
                    self.update(.cellular)
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.update(.ethernet)
                } else {
                    self.update(.undetermined)
                }
            }
            if observeNetworkChanges {
                nwPathMonitor.start(queue: .main)
            }
        } else {
            // Fallback on earlier versions
            // Remove when dropping iOS 11 and use NWPath (see git history)
            reachability = (try? Reachability())
            reachability?.whenReachable = { [weak self] reachability in
                guard let self = self else { return }
                self.update(reachability.connection == .wifi ? .wifi : .cellular)
            }
            reachability?.whenUnreachable = { [weak self] _ in
                guard let self = self else { return }
                self.update(.none)
            }
            if observeNetworkChanges {
                try? reachability?.startNotifier()
            }
        }
    }

    func update(_ newType: ConnectionType) {
        guard newType != connectionType else { return }
        connectionType = newType
    }
}

extension NetworkUtility {
    enum ConnectionType: String, CustomStringConvertible {
        case undetermined, none, ethernet, wifi, cellular
        var cellular: CellularType { CellularType.current }
        var description: String { rawValue }
    }

    enum CellularType {
        case none, twoG, threeG, fourG, fiveG, unknown
        var description: String? {
            switch self {
            case .none: return nil
            case .twoG: return "2g"
            case .threeG: return "3g"
            case .fourG: return "4g"
            case .fiveG: return "5g"
            case .unknown: return "Unknown"
            }
        }

        var carrierName: String {
            var name = "None"
            if ProcessInfo.isRunningDebugSessionSimulator {
                name = "Simulator"
            } else {
                #if os(iOS) && !targetEnvironment(macCatalyst)
                    let networkInfo = CTTelephonyNetworkInfo()
                    let carrier = networkInfo.subscriberCellularProvider
                    name = carrier?.carrierName ?? name
                #endif
            }
            return name
        }

        static var current: CellularType {
            if ProcessInfo.isRunningDebugSessionSimulator {
                return .none
            } else {
                #if os(iOS) && !targetEnvironment(macCatalyst)
                    guard let radioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology else {
                        return .none
                    }
                    switch radioAccessTechnology {
                    case CTRadioAccessTechnologyGPRS,
                         CTRadioAccessTechnologyEdge,
                         CTRadioAccessTechnologyCDMA1x:
                        return .twoG
                    case CTRadioAccessTechnologyWCDMA,
                         CTRadioAccessTechnologyHSDPA,
                         CTRadioAccessTechnologyHSUPA,
                         CTRadioAccessTechnologyCDMAEVDORev0,
                         CTRadioAccessTechnologyCDMAEVDORevA,
                         CTRadioAccessTechnologyCDMAEVDORevB,
                         CTRadioAccessTechnologyeHRPD:
                        return .threeG
                    case CTRadioAccessTechnologyLTE:
                        return .fourG
                    default:
                        if #available(iOS 14.1, *) {
                            if [CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR]
                                .contains(radioAccessTechnology) {
                                return .fiveG
                            }
                        }
                        return .unknown
                    }
                #else
                    return .none
                #endif
            }
        }
    }
}
