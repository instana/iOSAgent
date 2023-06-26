//
//  ViewController.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//
import UIKit
import InstanaAgent

let metricSubscriptionKey = "KeyMetricSubscription"
let metricSubscriptionFlagDefault = 0// default value if key not exist
let metricSubscriptionFlagYes = 1   // user agreed to subscribe to metric events
let metricSubscriptionFlagNo = 2    // user rejected subscribtion to metric events
let alertTitleInstanAgent = "Instana Agent Test"
let msgMetricSubscriptionConsent = "Would you allow app crash logs sent to server?"
let msgCrashNow = "Press OK button to crash running test app."
let msgNoCrashTest = "You rejected metric subscription, no more crash testing."
let msgDeviceVersionTooLow = "Device version too low.\nYou need iOS 14.0 or above to test crash catching/sending."

class ViewController: UITabBarController {

    private let floatingButton: UIButton = {
        let button = UIButton(frame: CGRect(x:0, y:0, width:70, height:70))
        button.backgroundColor = .systemGray
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "plus",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .medium))
            button.setImage(image, for: .normal)
        }
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.layer.shadowOpacity = 0.2
        button.layer.cornerRadius = 35
        return button
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        //add a floating button to crash app
        view.addSubview(floatingButton)
        floatingButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        floatingButton.frame = CGRect(x: view.frame.size.width - 120,
                                      y: view.frame.size.height - 180,
                                      width: 70, height:70)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc private func didTapButton() {
//        return UserDefaults.standard.removeObject(forKey: metricSubscriptionKey)
        guard Instana.canSubscribeCrashReporting() else {
            return iOSVersionTooLowAlert()
        }

        let subscribeFlag = UserDefaults.standard.integer(forKey: metricSubscriptionKey)
        if subscribeFlag == metricSubscriptionFlagYes {
            //app should have read this flag already and subscribed to metric events
            return crashTestNow() //proceed to crash testing
        }
        if subscribeFlag == metricSubscriptionFlagNo {
            return crashCatchingDisabledAlert() //user rejected metric subcription (crash report)
        }

        // show consent alert
        let alert = UIAlertController(title: alertTitleInstanAgent,
                                      message: msgMetricSubscriptionConsent,
                                      preferredStyle: .alert)

        let noAction = UIAlertAction(title: "No", style: .default) { (action) in
            UserDefaults.standard.set(metricSubscriptionFlagNo, forKey: metricSubscriptionKey)
        }
        let yesAction = UIAlertAction(title: "Yes", style: .cancel) { (action) in
            UserDefaults.standard.set(metricSubscriptionFlagYes, forKey: metricSubscriptionKey)
            Instana.subscribeCrashReporting()
            self.crashTestNow()
        }
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true)
    }

    private func crashTestNow() {
        let alert = UIAlertController(title: alertTitleInstanAgent,
                                      message: msgCrashNow,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default){ (action) in
            let testArr = [0, 1, 2]
            let idx = Int.random(in: 10..<60)
            print(testArr[idx])
//            let excp = NSException(name: NSExceptionName.characterConversionException, reason: "NSException reason")
//            excp.raise()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    private func crashCatchingDisabledAlert() {
        let alert = UIAlertController(title: alertTitleInstanAgent,
                                      message: msgNoCrashTest,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }

    private func iOSVersionTooLowAlert() {
        let alert = UIAlertController(title: alertTitleInstanAgent,
                                      message: msgDeviceVersionTooLow,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
