#!/bin/bash -e

xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentTests' test -testPlan InstanaAgentTests | xcpretty
xcodebuild test -destination 'name=iPhone 11' -scheme 'InstanaAgentTests' test -testPlan InstanaAgentIntegrationTests | xcpretty

