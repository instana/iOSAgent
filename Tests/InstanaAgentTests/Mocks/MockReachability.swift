//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation
import SystemConfiguration
@testable import InstanaAgent

class MockReachability: Reachability {

    override var connection: Reachability.Connection { stubbedConnection }
    var stubbedConnection: Reachability.Connection!

    convenience init(connection: NetworkUtility.ConnectionType) throws {
       guard let ref = SCNetworkReachabilityCreateWithName(nil, "hostname") else {
            throw ReachabilityError.failedToCreateWithHostname("hostname", SCError())
        }
        self.init(reachabilityRef: ref, queueQoS: .default, targetQueue: nil, notificationQueue: nil)
        switch connection {
        case .cellular:
            whenReachable?(self)
            self.stubbedConnection = .cellular
        case .wifi:
            whenReachable?(self)
            self.stubbedConnection = .wifi
        case .undetermined: whenUnreachable?(self)
            self.stubbedConnection = .unavailable
        case .none: whenUnreachable?(self)
            self.stubbedConnection = Reachability.Connection.unavailable
        }
    }

    required init(reachabilityRef: SCNetworkReachability, queueQoS: DispatchQoS = .default, targetQueue: DispatchQueue? = nil, notificationQueue: DispatchQueue? = .main) {
        super.init(reachabilityRef: reachabilityRef, queueQoS: queueQoS, targetQueue: targetQueue, notificationQueue: notificationQueue)
    }
}
