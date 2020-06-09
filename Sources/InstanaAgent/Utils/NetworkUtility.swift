import CoreTelephony
import Foundation

class NetworkUtility {
    private(set) var connectionType: ConnectionType = .undetermined {
        didSet {
            if oldValue != .undetermined {
                connectionUpdateHandler(connectionType)
            }
        }
    }

    var connectionUpdateHandler: (ConnectionType) -> Void = { _ in }

    private let reachability: Reachability?

    init(reachability: Reachability? = nil) {
        let reachability = reachability ?? (try? Reachability())
        self.reachability = reachability

        // Remove when dropping iOS 11 and NWPath (see git history)
        reachability?.whenReachable = { [weak self] reachability in
            guard let self = self else { return }
            self.update(reachability.connection == .wifi ? .wifi : .cellular)
        }
        reachability?.whenUnreachable = { [weak self] _ in
            guard let self = self else { return }
            self.update(.none)
        }
        try? reachability?.startNotifier()
    }

    func update(_ newType: ConnectionType) {
        guard newType != connectionType else { return }
        connectionType = newType
    }
}

extension NetworkUtility {
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
            if ProcessInfo.isRunningDebugSessionSimulator {
                return "Simulator"
            } else {
                let networkInfo = CTTelephonyNetworkInfo()
                let carrier = networkInfo.subscriberCellularProvider
                return carrier?.carrierName ?? "None"
            }
        }

        static var current: CellularType {
            if ProcessInfo.isRunningDebugSessionSimulator {
                return .none
            } else {
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
                    return .unknown
                }
            }
        }
    }

    enum ConnectionType: String, CustomStringConvertible {
        case undetermined, none, wifi, cellular
        var cellular: CellularType { CellularType.current }
        var description: String {
            switch self {
            case .none: return "None"
            case .wifi: return "Wifi"
            case .cellular: return CellularType.current.rawValue
            case .undetermined: return "Unknown"
            }
        }
    }
}
