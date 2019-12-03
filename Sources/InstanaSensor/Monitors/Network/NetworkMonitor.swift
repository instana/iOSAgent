//  Created by Nikola Lajic on 3/26/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation
import Network

@objc public class NetworkMonitor: NSObject {
    enum ConnectionType: String {
        case wifi, cellular
    }
    
    static let shared = NetworkMonitor()
    private(set) var connectionType: ConnectionType?
    private let queue = DispatchQueue(label: "NetworkMonitor")
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
                    self.connectionType = nil
                    return
                }
                if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else {
                    self.connectionType = nil
                }
            }
        }
        return monitor
    }()
    
    override init() {
        super.init()
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
