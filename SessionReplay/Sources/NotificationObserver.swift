//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
class NotificationObserver {
    weak let stagingManager: StagingManager?
    var currentOrientation: UIInterfaceOrientation?
    var keyboardShow = false

    /// Returns the current interface orientation. Replaceable in tests.
    var orientationProvider: () -> UIInterfaceOrientation? = {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }?
            .interfaceOrientation
    }

    init(stagingManager: StagingManager) {
        self.stagingManager = stagingManager
        DispatchQueue.main.async {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
    }

    deinit {
        stopObserving()
        DispatchQueue.main.async {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
     }

    @objc private func appWillEnterForeground() {
        reportNotification(eventType: UserActionEnum.appState,
                           value: AppStateValueEnum.foreground.rawValue,
                           valueKey: userActionKey_appState)
    }

    @objc private func appDidEnterBackground() {
        reportNotification(eventType: UserActionEnum.appState,
                           value: AppStateValueEnum.background.rawValue,
                           valueKey: userActionKey_appState)
    }

    @objc func handleOrientationChange() {
        guard let orientation = orientationProvider() else { return }
        processOrientationChange(orientation)
    }

    private func processOrientationChange(_ newOrientation: UIInterfaceOrientation) {
        var direction: OrientationValueEnum
        switch newOrientation {
        case .portrait:
            direction = OrientationValueEnum.Portrait
        case .portraitUpsideDown:
            direction = OrientationValueEnum.Portrait
        case .landscapeLeft:
            direction = OrientationValueEnum.landscape
        case .landscapeRight:
            direction = OrientationValueEnum.landscape
        default:
            direction = OrientationValueEnum.unknown
        }
        if newOrientation != currentOrientation {
            // initial orientation do not send to backend
            if currentOrientation != nil {
                reportNotification(eventType: UserActionEnum.orientation,
                                   value: direction.rawValue,
                                   valueKey: userActionKey_orientationChange)
            }
            currentOrientation = newOrientation
        }
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if !keyboardShow {
            keyboardShow = true
//            let positionRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            reportNotification(eventType: UserActionEnum.keyboardOperation,
                               value: KeyboardOperationValueEnum.open.rawValue,
                               valueKey: userActionKey_keyboardOperation)
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        if keyboardShow {
            reportNotification(eventType: UserActionEnum.keyboardOperation,
                               value: KeyboardOperationValueEnum.close.rawValue,
                               valueKey: userActionKey_keyboardOperation)
            keyboardShow = false
        }
    }

    private func reportNotification(eventType: UserActionEnum, value: String, valueKey: String?) {
        let time = Instana.Types.Milliseconds(Date().millisecondsSince1970)
        stagingManager?.stageUserEvent(timestamp:time,
                                       eventType: eventType,
                                       eventValue: value,
                                       eventValueKey: valueKey)
    }
}
