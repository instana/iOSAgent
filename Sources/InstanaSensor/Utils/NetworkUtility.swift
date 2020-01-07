import CoreTelephony
import Foundation
import Network

class NetworkUtility {
    private(set) var connectionType: ConnectionType = .undetermined {
        didSet {
            if oldValue != .undetermined {
                connectionUpdateHandler(connectionType)
            }
        }
    }

    private let queue = DispatchQueue(label: "NetworkUtility")
    var connectionUpdateHandler: (ConnectionType) -> Void = { _ in }

    @available(iOS 12.0, *)
    lazy var pathMonitor = NWPathMonitor()

    init(connectionType: ConnectionType? = nil) {
        if #available(iOS 12.0, *) {
            self.connectionType = connectionType ?? ConnectionType.from(pathMonitor.currentPath)

            // Don't run during tests - it's not testable anyway
            if !ProcessInfo.processInfo.isRunningTests {
                pathMonitor.pathUpdateHandler = { [weak self] path in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.update(ConnectionType.from(path))
                    }
                }
                pathMonitor.start(queue: queue)
            }
        }
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
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            return carrier?.carrierName ?? "None"
        }

        static var current: CellularType {
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

        @available(iOS 12.0, *)
        static func from(_ path: NWPath) -> ConnectionType {
            guard path.status == .satisfied else {
                return .undetermined
            }
            if path.usesInterfaceType(.cellular) {
                return .cellular
            } else if path.usesInterfaceType(.wifi) {
                return .wifi
            }
            return .undetermined
        }
    }
}
