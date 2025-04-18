# Changelog

## 1.9.1
- add W3C trace headers for http requests if enableW3CHeaders is configured to true

## 1.9.0
- fix usi (user session id) bug for default configuration
- send app foreground/background state along with each beacon
- add `trustDeviceTiming` configuration option for backend to trust the device timing
- enable app launch time monitoring by default, other performance monitoring off

## 1.8.9
- fix pod lib lint error

## 1.8.8
- add option to configure rate limit, drop beacons and performance beacons
- send drop beacons and performance beacons (app launch time, low memory warning, application not responding)to Instana backend

## 1.8.7
- queryTrackedDomainList configuration to capture http query parameters if url is in the white listed RegExp array
- app launch time measure

## 1.8.6
- fix memory leak

## 1.8.5
- detect Application Not Responding scenario
- remove code for iOS versions lower than 12

## 1.8.4
- better memory management
- add drop beacon handler

## 1.8.3
- update minimum supported iOS version to 12 (was 11 before)
- do not rate limit session start beacon and crash beacons
- fix typo of crash exception code

## 1.8.2
- crash beacon errorType value update
- When http request failed, track statusCode along with error message

## 1.8.1
- added functionality to accept internal metadata from cross-platform agents

## 1.8.0
- add to mobile feature list if `autoCaptureScreenNames` is enabled
- add Privacy Manifest File PrivacyInfo.xcprivacy to iOSAgent
- update to Swift version 5.4, update GzipSwift version to 6.0.1 for spm

## 1.7.0
- introduce `autoCaptureScreenNames` to auto capture view names and `debugAllScreenNames` to debug all screen names

## 1.6.9
- Support CustomMetric field in reportEvent method

## 1.6.8
- Add more meta data to crash beacon
- Add more exceptionType processing to crash beacon
- Display crash terminationReason as meta data rather than error message
- Add Objective-C target ObjectiveCAppExample to InstanaAgentExample
- Support hybrid agent id and version (if invoked by flutter-agent/react-native-agent)

## 1.6.7
- Add more raw crash payload info to stackTrace

## 1.6.6
- Fix client side crash symbolication for arm64e architecture
- Fix unit test cases that failed in command line execution
- Fix unit test cases that failed in Xcode 15
- Change beacon id from 128 bit UUID to 64 bit hex string
- Suspend beacon flushing (on low battery and/or cellular network) becomes configurable

## 1.6.5
- Add crash to mobile feature list and send to Instana backend
- Add user_session_id (usi) to beacons

## 1.6.4
- Fix issue for setCaptureHeaders method not capture http response headers

## 1.6.3
- Fix duplicated beacons issue

## 1.6.2
- [Tech Preview] Add sample code in InstanaAgentExample app on how to enable crash reporting to Instana backend
- Once in slow send mode, periodically resend 1 beacon. Once out of slow send mode, flush all beacons immediately.

## 1.6.1
- Fix crash caused by appendMetaData() inside InstanaProperties class
- Improve error handling on beacon send failure

## 1.6.0
- Refactor code and add more unit test cases

## 1.5.2
- Add new atomic types for some collections to improve thread safety

## 1.5.1
- Improve thread safety

## 1.5.0
- Add new feature to capture HTTP header fields by providing an array of NSRegularExpression

## 1.4.0
- Add new feature to redact password, key, secrets from HTTP query parameters
- Improve thread safety

## 1.3.1
- Implement task-based authentication challenge method and forward to session-based if needed

## 1.3.0
- Update flushing mechanism (align with Android)
- Add retry with exponential backoff

## 1.2.4
- Improve checking urls for URLProtocol usage

## 1.2.3
- Some minor project clean ups

## 1.2.2
- Do not forward urlSession(_ session: dataTask: didReceive:completionHandler) anymore (Response might get lost)

## 1.2.1
- Make compatible with older Xcode versions (prior 12.1)
- Clean up tests and CI pipeline
- Add AFNetworking and Alamofire to demo project

## 1.2.0
- Added new flag `collectionEnabled` to set up Instana without data collection. Instrumentation can be enabled later using this property. This allows apps to start Instana with a delay if users are asked for consent beforehand.

## 1.1.18
- Fix setting responseSize
- Make originalTask weak
- Always finishTasksAndInvalidate URLSession to avoid leaks

## 1.1.17
- Forward all URLSession delegates to the client

## 1.1.16
- Add httpCaptureConfig: automaticAndManual to enable parallel manual and automtic http instrumentation

## 1.1.15
- Forward URLAuthenticationChallenge properly

## 1.1.14
- Fix instrumenting URLSessionDownloadTask

## 1.1.13
- Use specific URLSession Tasks
- Update tests

## 1.1.12
- Improve example project
- Add capability for macOS (AppKit)
- Align carrier type and effective connection type with Android and Web

## 1.1.11 Beta
- Add 5G as carrier type
- Update tests

## 1.1.10 Beta
- ReportEvent: Use current visible view name if passed viewName is empty or nil
- Example project clean up

## 1.1.9 Beta
- Skipped (CocoaPods conflicts)

## 1.1.8 Beta
- Dispatch method on serial queue

## 1.1.7 Beta
- Use active as default value for InstanaApplicationStateHandler
- User properties can be set individually (name, id or email address)
- Add manual HTTP monitoring for URLs (parallel to URLRequests)
- Add HTTPCaptureResult type for finishing manual HTTP monitoring

## 1.1.6 Beta
- Dispatch background flush on queue (synchronized)

## 1.1.5 Beta
- Remove UIApplication.shared to enable InstanaAgent for extensions

## 1.1.4 Beta
- Add Rate limiter to avoid an extensive usage of Instana
- Improve concurrency and threading
- Update tests

## 1.1.3 Beta
- Validates the length of properties, meta data and view name gracefully without throwing fatalError. Any value that exceeds the limit will be truncated

## 1.1.2 Beta
- Adds default URLs (currenty Instabug) to be ignored during monitored

## 1.1.1 Beta
- Fix prequeue threading issue

## 1.1.0 Beta
- Adds the ability to report custom events
- Adds the ability to report custom events
- Fixes bug with missing backend
- Fixes bug with unknown carrier name
- Avoids sending beacon duplicates
- Removes fatalError for missing Instana agent configuration (Uses logging instead)
- Some more bug fixes (Avoids circular reporting and fix connection type parameter)
- Fixes exposing public methods to Objective-C
- Improves Unit Tests

## 1.0.6 Beta 6
04/23/2020
* Defer reporting and setting the view names. This helps us to a prequeue beacons, collect all properties and the first appearing view
* ViewNames for http requests can be set at the capture start when using manual http capture mode
Update tests

## 1.0.5 Beta 5
04/16/2020
Fix CoreBeacon fields for bundleIdentifier and platform

## 1.0.4
nothing - just an empty release

## 1.0.3 Beta 4
04/14/2020
Sending the agent version to Instana

## 1.0.2 Beta 3
03/23/2020
Improves flushing queue in the background. iOSAgent is also available to app extensions now.

## 1.0.1 Beta 2
03/12/2020
Removes WKWebView from being monitored automatically

## 1.0.0 Beta 1
01/30/2020
Adds monitoring

Session start
HTTP session monitoring (automatic or manual)
Optional:

Adds a method to set the visible view with an arbitrary name
Specific URLs can be excluded from monitoring
Specific URLSessions can be excluded from monitoring
Store Meta data / user information
Store user information
