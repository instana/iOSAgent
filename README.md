# Instana iOS SDK
Instana iOS SDK offers the following features:  

- Crash monitoring and reporting
- Performance alerts
- Remote call instrumentation

The SDK supports iOS 10.3 and above, and is usable from Swift and Objective-C.

## Setup

### Installation
#### Swift Package Manager
1. Just go into Xcode.
2 .Choose File -> Swift Packages -> Add Package Dependency -> Select your Xcode project
3. Enter this repository URL 

##### CocoaPods
To add Instana as a dependency edit your `Podfile` to include the following:

    pod 'Instana', :git => 'https://github.com/instana/ios-sensor'
    pod 'KSCrash/Core', :git => 'https://github.com/MrNickBarker/KSCrash'
    
> Instana uses a custom fork of KSCrash that expands the interface to better support Swift, and adds local crash identifiers to support individual report deletion.

Don't forget to run `pod install` to download the dependencies.

### Initialization

The recommended way to initialize the SDK is to create and download a configuration file from [TODO](). Move the configuration to the root of your project and add it in the correct targets.

`Instana.setup()` will search for `InstanaConfiguration.plist` in the project root.

	import Instana

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		Instana.setup()
		return true
	}
	
> To capture the most data, the initialization method should be called as early as possible, preferably in `application(_:, didFinishLaunchingWithOptions:)`.

If you would like to have different configurations (for example, debug and production) or use a different configuration name, you can use `Instana.setup(with:)` to provide a custom absolute path.

	#if DEBUG
		Instana.setup(with: // path to debug configuration)
	#else
		Instana.setup()
	#endif

If you don't want to use a configuration file you can use `Instana.setup(withKey:reportingUrl:)` and programmatically configure the SDK. 

    Instana.setup(withKey: "your-key")
    
>`reportingUrl` is optional and should only be used for on-premisses Instana installations.

## Events
All communication to the Instana backend is done trough events. 

> Other than custom events, there is no way for the end user to send events, even so some configuration options are exposed.

`bufferSize` represents the size of the ring buffer in which events are stored. Events can be overwritten if too many are triggered before a buffer flush. If you expect a large volume of events you can increase the buffer size.

`suspendReporting` allows developers to decide in which cases to suspend the sending of events to the Instana backend. The options are: `never`, `lowBattery`, `cellularConnection`, `lowBatteryAndCellularConnection`.

### Custom Events
If you wish to mark a specific event in your application, you can use a custom event to send it to Instana.

	let event = InstanaCustomEvent(name: "my-event", timestamp: Date().timeIntervalSince1970, duration: 2.5)
    Instana.events.submit(event: event)
    
> `timestamp` and `duration` are optional for custom events.

## Remote Call Instrumentation
The following configuration options are available: `automaticAndManual`, `automatic`, `manual`, `none`.

	Instana.remoteCallInstrumentation.reporting = .automaticAndManual

### Automatic 
If automatic remote call instrumentation is enabled, calls made with the shared `URLSession` will automatically be tracked. 

Automatic instrumentation can be enabled for a custom `URLSession` by calling:

    Instana.remoteCallInstrumentation.install(in: sessionConfiguration)
    
> A session's configuration can't be changed after initialization, so make sure to call this before creating a session.

### Manual
In case you you are not using `URLSession` or want to customize the results, it is possible to manually instrument remote calls.

While starting a request you should also create a marker:

    let marker = Instana.remoteCallInstrumentation.markCall(to: "your-url", method: "GET")
    
Once the request finishes or fails, use one of the markers completion methods:

	marker.endedWith(responseCode: 200, responseSize: // optionally calculate response size)
	// or
	marker.endedWith(error: error, responseSize: // optionally calculate response size)
	// or
	marker.canceled()
	
## Crash reporting
Crash reporting is enabled by default. In case you are using a different crash reporting solution, or don't want crash reporting, it can only be disabled via a configuration file.

### Crash report symbolication
The easiest way to upload dSYM files to Instana for crash report symbolication, is by using [Fastlane](https://fastlane.tools/) and the [Instana plugin](https://github.com/instana/instana-fastlane-plugin).

Alternatively you can manually upload dSYM files to the Instana backend. // TODO

### Breadcrumbs
To assist you in determining the casue of a crash you can leave breadcrumbs in your app.

	Instana.crashReporting.leave(breadcrumb: "User logged in")
	
The total number of breadcrumbs is limited to 100, after that newer breadcrumbs will overwrite older ones.
> Breadcrumbs will be truncated to 140 characters.

## Performance Alerts
Performance alerts can be individually disabled/enabled and configured.

### Memory Warning
Low memory alerts will get reported on the standard low memory system event which triggers the `UIApplication.didReceiveMemoryWarningNotification` notification.

### Application Not Responding (ANR)
ANR events will get reported after the main thread is blocked for more than the duration specified in the configuration. It can also be adjusted at runtime, for example:

	Instana.alerts.applicationNotRespondingThreshold = 1
	
will trigger an ANR alert after the main thread has been blocked for more than one second.

To disable ANR alerts set the threshold to `nil`.

Depending on the threshold settings, an ANR alert might overlap with a frame rate dip alert.

### Frame-rate Dip
If the application frame-rate dips below the configured threshold, a frame-rate dip alert will be triggered. For example:

	Instana.alerts.framerateDipThreshold = 20

will trigger an alert if the frame-rate drops below 20 frames per second.

To disable frame-rate dip alerts set the threshold to `nil`.
