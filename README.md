# Instana iOSAgent

**[Changelog](https://github.com/instana/iOSAgent/blob/master/Changelog.md)** |

---

iOS agent to use Instana for your iOS app. The monitoring currently supports:

- Session Start
- Capture HTTP sessions automatically or manually
- Automatic delivery of device & app information (like bundle identifer, version, language, iOS device information)
- Send custom event (This can be especially helpful to send logs, to track additional performance metrics or errors.)

Optionally:
- Ignore full URLs by regex or full URLs
- Set global meta data (key/value)
- Set user specific data (like id, name and email)
- Set the current visible view to match with the HTTP sessions  


## Installation

To install the iOS agent, use Swift Package Manager (via Xcode) or CocoaPods.

#### Swift Package Manager

1. Open Xcode.
2. Select File -> Swift Packages -> Add Package Dependency -> Your Xcode project.
3. Enter the https://github.com/instana/iOSAgent repository.

#### CocoaPods

1. Within your `Podfile` specification, add the following:

   `pod 'InstanaAgent'`

2. To download the dependencies, run `pod install`.

#### Setup
Just initialize the Instana iOS agent with the following setup. Make sure to call setup very early in `didFinishLaunchingWithOptions`

```
import InstanaAgent

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

	Instana.setup(key: <Your Instana Key>, reportingURL: <Your Instana instance URL>)

	....
	return true
}
```

### API

See [API page](https://docs.instana.io/products/mobile_app_monitoring/ios_api/).

