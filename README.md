# Instana iOSAgent

**[Changelog](https://github.com/instana/iOSAgent/blob/master/Changelog.md)** |

---

iOS agent to use Instana for your iOS app. The monitoring currently supports:

- Session Start
- Capture HTTP sessions automatically or manually
- Automatic delivery of device & app information (like bundle identifer, version, language, iOS device information)
- Send custom event (This can be especially helpful to send logs, to track additional performance metrics or errors.)
- [Beta] Crash reporting, plus CPU exception, disk write exception, hang diagnostics and app launch diagnostics
- [Beta] Automatic screen name capture

Optionally:
- Ignore full URLs by regex or full URLs
- Set global meta data (key/value)
- Set user specific data (like id, name and email)
- Set the current visible view to match with the HTTP sessions  

## Requirements
- iOS 11+
- Swift 5.4+

## Installation

To install the iOS agent, use Swift Package Manager (via Xcode) or CocoaPods.

#### Swift Package Manager

1. Open Xcode.
2. Open your Xcode project.
2. Select menu **`File`** -> **`Add Package Dependencies...`**
3. In the window that pops up, enter the repository https://github.com/instana/iOSAgent in the **Search or Enter Package URL** field. Then, select **`iosagent`** from the search result and click **`Add Package`** button.

#### CocoaPods

1. Within your `Podfile` specification, add the following:

   `pod 'InstanaAgent'`

2. To download the dependencies, run `pod install`.

#### Setup
Just initialize the Instana iOS agent with the following setup. Make sure to call setup very early in `didFinishLaunchingWithOptions`

```
import InstanaAgent

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let options = InstanaSetupOptions(enableCrashReporting: <true or false>)
	Instana.setup(key: <Your Instana Key>, reportingURL: <Your Instana instance URL>, options: options)

	....
	return true
}
```

### Notes on diagnostic log report

1. Diagnostic test, crash as an example, needs to be done on physical devices: iPhone, iPad etc. Simulator is of no help.
2. The lowest versions that support crash reporting are iOS 14.0 and macOS 12.0.
3. A valid bundle id other than com.instana.ios.InstanaAgentExample for your test app is also a must.

### API

See [API page](https://www.ibm.com/docs/en/instana-observability/current?topic=applications-ios-api).

