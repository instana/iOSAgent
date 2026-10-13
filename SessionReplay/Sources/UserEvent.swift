//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
class UserEvent {
    let config: InstanaSessionReplayConfig
    weak let stagingManager: StagingManager?
    weak var notificationObserver: NotificationObserver?
    var lastTouchTime: Instana.Types.Milliseconds = Date().millisecondsSince1970

    init(config: InstanaSessionReplayConfig, stagingManager: StagingManager) {
        self.config = config
        self.stagingManager = stagingManager
    }

    // MARK: - sendEvent

    func processSendEvent(event: UIEvent) {
        guard notificationObserver?.keyboardShow != true else { return }
        guard event.type == .touches, let touches = event.allTouches, !touches.isEmpty else {
            return
        }

        lastTouchTime = Date().millisecondsSince1970
        for touch in touches {
            guard let win = touch.window else { continue }

            let locationInWindow = touch.location(in: win)

            if isTouchBegin(touch) {
                if touch.touchEntry == nil {
                    var viewClassType: String?
                    var viewId: String?
                    if let targetView = findTargetView(for: touch) {
                        (viewClassType, viewId) = getViewClassAndId(targetView: targetView)
                    }
                    let touchEntry = TouchEntry(timestamp: Instana.Types.Milliseconds(Date().millisecondsSince1970),
                                                locationInWindow: locationInWindow,
                                                viewClassName: viewClassType,
                                                viewId: viewId,
                    )
                    touch.touchEntry = touchEntry
                }
            } else if isTouchMove(touch) {
                if let touchEntry = touch.touchEntry {
                    touchEntry.appendTouch(locationInWindow: locationInWindow,
                                          timestamp: Instana.Types.Milliseconds(Date().millisecondsSince1970))
                }
            } else if isTouchFinished(touch) {
                if let touchEntry = touch.touchEntry {
                    touchEntry.appendTouch(locationInWindow: locationInWindow,
                                      timestamp: Instana.Types.Milliseconds(Date().millisecondsSince1970))
                    touchEntry.finish(isCancelled: touch.phase == UITouch.Phase.cancelled)
                    stagingManager?.stageUserEvent(timestamp: touchEntry.timestamp,
                                                   eventType: UserActionEnum.touch,
                                                   viewClassName: touchEntry.viewClassName,
                                                   viewId: touchEntry.viewId,
                                                   coordinates: touchEntry.getCoordinates())
//                    touch.touchEntry = nil
                }
            } else {
                Instana.log("UserEvent touch skipped: type=\(event.type), touch.phase=\(touch.phase)", level: .debug)
            }
        }
    }

    private func isTouchBegin(_ touch: UITouch) -> Bool {
        if touch.phase == UITouch.Phase.began {return true}
        if #available(iOS 13.4, *) {
            if touch.phase == UITouch.Phase.regionEntered {return true}
        }
        return false
    }

    private func isTouchMove(_ touch: UITouch) -> Bool {
        if touch.phase == UITouch.Phase.moved {return true}
        if #available(iOS 13.4, *) {
            if touch.phase == UITouch.Phase.regionMoved {return true}
        }
        return false
    }

    private func isTouchEnd(_ touch: UITouch) -> Bool {
        if touch.phase == UITouch.Phase.ended {return true}
        if #available(iOS 13.4, *) {
            if touch.phase == UITouch.Phase.regionExited {return true}
        }
        return false
    }

    private func isTouchCancelled(_ touch: UITouch) -> Bool {
        if touch.phase == UITouch.Phase.cancelled {return true}
        return false
    }

    private func isTouchFinished(_ touch: UITouch) -> Bool {
        if touch.phase == UITouch.Phase.ended {return true}
        if #available(iOS 13.4, *) {
            if touch.phase == UITouch.Phase.regionExited {return true}
        }
        if touch.phase == UITouch.Phase.cancelled {return true}
        return false
    }

    private func findTargetView(for touch: UITouch) -> UIView? {
        guard let window = touch.window else { return nil }
        let location = touch.location(in: window)
        return window.hitTest(location, with: nil)
    }


    // MARK: - sendAction

    func processSendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) {
        guard let allTouches = event?.allTouches, allTouches.count == 1, let tap = allTouches.first else {
            return
        }
        guard let win = tap.window else { return }

        var lastTouchEntry: TouchEntry?
        if tap.phase == UITouch.Phase.ended {
            lastTouchEntry = tap.touchEntry
            if lastTouchEntry == nil {
                let locationInWindow = tap.location(in: win)

                var viewClassType: String?
                var viewId: String?
                if let targetView = findTargetView(for: tap) {
                    (viewClassType, viewId) = getViewClassAndId(targetView: targetView)
                }
                lastTouchEntry = TouchEntry(timestamp: Instana.Types.Milliseconds(Date().millisecondsSince1970),
                                            locationInWindow: locationInWindow,
                                            viewClassName: viewClassType,
                                            viewId: viewId)
                Instana.log("sendAction new touchEntry=\(lastTouchEntry!.description)", level: .debug)
            }
        }

        guard let _ = target, let _ = sender, let lastTouchEntry = lastTouchEntry,
              let viewClassName = lastTouchEntry.viewClassName else { return }

        stagingManager?.stageUserEvent(timestamp: Instana.Types.Milliseconds(Date().millisecondsSince1970),
                                       eventType: UserActionEnum.tap,
                                       viewClassName: viewClassName,
                                       viewId: lastTouchEntry.viewId,
                                       coordinates: lastTouchEntry.getCoordinates())
    }

    private func getViewClassAndId(targetView: UIView) -> (String?, String?) {
        let viewClassName = "\(type(of: targetView))"
        var viewId: String? = targetView.accessibilityIdentifier
        if viewId == nil && targetView.tag != 0 {
            viewId = "tag \(targetView.tag)"
        }
        return (viewClassName, viewId)
    }
}


var associatedTouchEntryIDKey: String = "TrackedUITouchEvent"

internal extension UITouch {
    var touchEntry: TouchEntry? {
        set {
            withUnsafePointer(to: &associatedTouchEntryIDKey) {
                objc_setAssociatedObject(self, $0, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }

        get {
            withUnsafePointer(to: &associatedTouchEntryIDKey) {
                objc_getAssociatedObject(self, $0) as? TouchEntry
            }
        }
    }
}
