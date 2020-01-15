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

The iOSAgent uses the following sub-dependencies:
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

##### Manual HTTP monitoring
To capture HTTP sessions manually you must setup with the following

```
Instana.setup(key: <Your Instana Key>, reportingURL: <Your Instana instance URL>, httpCaptureConfig: .manual)
```

You can also set `httpCaptureConfig: .none` to completely disable HTTP session monitoring. 
To capture HTTP sessions manually you have to do the following: 
Start the capture of the http session before using the URLRequest in a URLSession (you can set a viewName optionally):

```
let marker = Instana.startCapture(request)
URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
    	marker.finish(error: error)
    } else {
    	let code = (response as? HTTPURLResponse)?.statusCode ?? 200
    	marker.finish(responseCode: code)
    }
}.resume()
```

You can also set the HTTP response size manually via the URLSessionDelegate. Like the following:

```
func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
	marker.set(responseSize: Instana.Types.HTTPSize(task: task, transactionMetrics: metrics.transactionMetrics))
}
```

##### Ignore specific HTTP requests
You ignore URLs that match with the given regular expressions

```
let regex = try! NSRegularExpression(pattern: ".*http:.*")
Instana.setIgnoreURLs(matching: [regex])
```
With a regular expression (i.e. `/.*(&|\?)password=.*/i`) you can ignore all HTTP requests that contain any sensitive data like a password
You can also ignore full URLs like: 

```
Instana.setIgnore(urls: [URL(string: "https://www.example.com")!])
``` 

##### Meta data information
Optionally you can set some global meta data after the setup: 

```
Instana.setMeta(value: "Value", key: "KEY")
Instana.setMeta(value: "DEBUG", key: "Env")
```

Meta data information that will be attached to each transmitted data (beacon). Consider using this to track UI configuration values, settings, feature flags… any additional context that might be useful for analysis.


##### User information
This information can optionally be sent with data transmitted to Instana. It can then be used to unlock additional capabilities such as: calculate the number of users affected by errors, to filter data for specific users and to see which user initiated a page load.

```
Instana.setUser(id: UUID().uuidString, email: "john@example.com", name: "John")
```

Note: By default, Instana will not associate any user-identifiable information to beacons. Please be aware of the respective data protection laws when choosing to do so. We generally recommend identification of users via a user ID. For Instana this is a completely transparent string that is only used to calculate certain metrics. Name and email can also be used to have access to more filters and a more pleasant presentation of user information.

##### View name
Set the current visible view represented by a custom name. For example:

```
Instana.setView(name: "UserDetails")
```
This name will be attached to all monitored beacons while your app is running in foreground. Any beacon created in background will be assigned to the view name "Background".
The name should be unique and not too technical or generic (not just like `WebViewController`) Consider something like: `WebView: Privacy policy`
Note: This must be handled manually since an iOS app can have multiple `UIWindow` or `UIViewController` showing at the same time.
You should call this method in `viewDidAppear`.



See [usage section](https://docs.instana.io/ecosystem/node-js/installation/#native-extensions).

### How it works
Once you started this agent via the setup method a start session will submitted to Instana. 
By default HTTP sessions will be be captured automatically. The agent uses Foundation's `NSURLProtocol` to monitor http requests and responses. In order to observe all `NSURLSession ` (also custom created) this agent does some method swizzling in the `NSURLSession`.
To opt-out automatic HTTP session monitoring you must capture every request & response manually ([Manual HTTP monitoring](#manual-http-monitoring)) .  

### API

See [API page](https://docs.instana.io/ecosystem/node-js/api/).
