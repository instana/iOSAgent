#!/bin/bash -e

xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaSensorTests' | xcpretty
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaSensorIntegrationTests' | xcpretty
