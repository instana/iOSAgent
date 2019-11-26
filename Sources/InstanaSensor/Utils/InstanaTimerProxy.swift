//  Created by Nikola Lajic on 3/11/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

protocol InstanaTimerProxiedTarget: class {
    func onTimer(timer: Timer)
}

/// The proxy is used to avoid the retain cycle caused by Timer retaining its target.
class InstanaTimerProxy {
    private weak var target: InstanaTimerProxiedTarget?
    
    @objc private func onTimer(timer: Timer) {
        if let target = target {
            target.onTimer(timer: timer)
        }
        else {
            timer.invalidate()
        }
    }
    
    static func timer(proxied: InstanaTimerProxiedTarget, timeInterval: TimeInterval, userInfo: Any? = nil, repeats: Bool = false) -> Timer {
        let proxy = InstanaTimerProxy()
        proxy.target = proxied
        return Timer(timeInterval: timeInterval, target: proxy, selector: #selector(onTimer(timer:)), userInfo: userInfo, repeats: repeats)
    }
}
