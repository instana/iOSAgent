#!/bin/bash
set -o pipefail
set -o xtrace
echo "Running Unit Tests"

scheme='InstanaAgentTests'

xcodebuild test -destination 'name=iPhone 13,OS=15.0' -scheme ''${scheme}'' | xcpretty --color -t
