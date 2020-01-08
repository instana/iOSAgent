import UIKit
import InstanaAgent

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if !isRunningTests {
            let url = URL(string: "<Your Instana instance URL>")!
            Instana.setup(key: "<Your Key>", reportingURL: url)
            Instana.setMeta(value: "Value", key: "KEY")
            Instana.setMeta(value: "DEBUG", key: "Env")
            Instana.setUser(id: UUID().uuidString, email: "email@example.com", name: "Christian")
            Instana.ignoreURL(matching: [".*http:.*"])
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
