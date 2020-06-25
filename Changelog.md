# Changelog

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
