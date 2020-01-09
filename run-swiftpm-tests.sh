#!/bin/bash -e
set -o pipefail
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentTests' | xcpretty
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentIntegrationTests' | xcpretty
