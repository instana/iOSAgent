# Instana iOSAgent

**[Changelog](CHANGELOG.md)** |
**[Contributing](CONTRIBUTING.md)** |

---

iOS agent to use Instana for your iOS app. The monitoring currently supports:

- Session Start
- Capture  HTTP sessions automatically or manually
- Automatic delivery of device & app information (like bundle identifer, version, language, iOS device information)

Optionally:

- Ignore full URLs by regex or full URLs
- Set global meta data (key/value)
- Set user specific data (like id, name and email)
- Set the current visible view to match with the HTTP sessions  


## Installation 

#### Swift Package Manager
1. Just go into Xcode.
2 .Choose File -> Swift Packages -> Add Package Dependency -> Select your Xcode project
3. Enter this repository URL 

#### CocoaPods
Edit your `Podfile` to include the following:

    pod 'Instana'    
Don't forget to run `pod install` to download the dependencies.

The iOS Instana agent uses the following sub-dependencies:
- [GzipSwift](https://github.com/1024jp/GzipSwift) to zip the http body
- [swift-nio](https://github.com/apple/swift-nio) for unit and integration tests


See [installation page](https://docs.instana.io/ecosystem/node-js/installation/).

#### Usage

##### Setup
Just initialize the Instana iOS agent with the following setup. Make sure to call setup very early in `didFinishLaunchingWithOptions`

```
import Instana

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
	
	Instana.setup(key: <Your Instana Key>, reportingURL: <Your Instana instance URL>)
	
	.... 
	return true
}
```


### How it works
Once you started this agent via the setup method a start session will submitted to Instana. 
By default HTTP sessions will be be captured automatically. The agent uses Foundation's `NSURLProtocol` to monitor http requests and responses. In order to observe all `NSURLSession ` (also custom created) this agent does some method swizzling in the `NSURLSession`.
To opt-out automatic HTTP session monitoring you must capture every request & response manually ([Manual HTTP monitoring](#manual-http-monitoring)) .  

### API

See [API page](https://docs.instana.io/ecosystem/node-js/api/).
