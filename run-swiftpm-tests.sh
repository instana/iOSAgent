#!/bin/bash -e

xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentTests'
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentIntegrationTests'
