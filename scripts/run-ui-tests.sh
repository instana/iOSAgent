#!/bin/bash
set -o pipefail
cd Dev
xcodebuild test -destination 'name=iPhone 11 Pro Max,OS=13.5' -scheme 'iOSAgentExample'
