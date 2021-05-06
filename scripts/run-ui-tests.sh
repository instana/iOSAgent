#!/bin/bash
set -o pipefail
(cd Dev && xcodebuild test -destination 'platform=iOS Simulator,name=iPhone 12,OS=14.5' -scheme 'iOSAgentUITests' | xcpretty --test --color)
