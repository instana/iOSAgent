# Changelog

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
