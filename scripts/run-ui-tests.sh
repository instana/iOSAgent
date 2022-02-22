#!/bin/bash
set -o pipefail
set -o xtrace

echo "Running UI Tests"
device=`xcrun simctl list 2>&1 | grep -oE 'iPhone 1.*?[^\(]+' | head -1 | awk '{$1=$1;print}'`
platform='iOS Simulator'
(cd Dev && xcodebuild test -destination "platform=$platform,name=$device" -scheme 'iOSAgentUITests' | xcpretty --test --color)
