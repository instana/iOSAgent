#!/bin/bash -e

xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaSensorTests'
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaSensorIntegrationTests'
