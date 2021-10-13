#!/bin/bash
set -o pipefail
set -o xtrace

echo "Running UI Tests"
(cd Dev && xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.0' -scheme 'iOSAgentUITests' | xcpretty --test --color)
