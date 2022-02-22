#!/bin/bash
set -o pipefail
echo "Running Unit Tests"

scheme='InstanaAgentTests'
device=`xcrun simctl list 2>&1 | grep -oE 'iPhone 1.*?[^\(]+' | head -1 | awk '{$1=$1;print}'`
platform='iOS Simulator'

set -v
xcodebuild test -destination "platform=$platform,name=$device" -scheme ''${scheme}'' | xcpretty --color -t
