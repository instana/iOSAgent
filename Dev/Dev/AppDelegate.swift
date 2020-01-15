import UIKit
import InstanaAgent

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if !isRunningTests {
            Instana.setup(key: InstanaKey, reportingURL: InstanaURL)
            Instana.setMeta(value: "Value", key: "KEY")
            Instana.setMeta(value: "DEBUG", key: "Env")
            Instana.setUser(id: UUID().uuidString, email: "email@example.com", name: "Christian")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

var isRunningTests: Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

var isRunningUITests: Bool {
    return ProcessInfo.processInfo.environment["UITestsActive"] == "true"
}

var InstanaKey: String {
    /// Will be added via a hidden (git ignored) environment variables - see build phase "Load Environment vars into info.plist"
    /// Make sure to have the .env-vars in your local Dev folder and ignore it in git
    /// Containing the two values like
    /// export INSTANA_REPORTING_URL=https://<YOUR URL>
    /// export INSTANA_REPORTING_KEY=<YOUR KEY>
    return Bundle.main.infoDictionary?["INSTANA_REPORTING_KEY"] as? String ?? ""
}

var InstanaURL: URL {
    let value = Bundle.main.infoDictionary?["INSTANA_REPORTING_URL"] as? String ?? ""
    return URL(string: value)!
}
