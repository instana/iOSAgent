//
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import Foundation

protocol InstanaTimerProxiedTarget: AnyObject {
    func onTimer(timer: Timer)
}

/// The proxy is used to avoid the retain cycle caused by Timer retaining its target.
class InstanaTimerProxy {
    private weak var target: InstanaTimerProxiedTarget?

    @objc func onTimer(timer: Timer) {
        if let target = target {
            target.onTimer(timer: timer)
        } else {
            timer.invalidate()
        }
    }

    static func timer(proxied: InstanaTimerProxiedTarget, timeInterval: TimeInterval, userInfo: Any? = nil, repeats: Bool = false) -> Timer {
        let proxy = InstanaTimerProxy()
        proxy.target = proxied
        return Timer(timeInterval: timeInterval, target: proxy, selector: #selector(onTimer(timer:)), userInfo: userInfo, repeats: repeats)
    }
}
