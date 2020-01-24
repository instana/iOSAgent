#!/bin/bash
set -o pipefail

while [ $# -gt 0 ]; do
  case "$1" in
    --ios=*)
      ios_version="${1#*=}"
      ;;
    --test=*)
      test_env="${1#*=}"
      ;;
    *)
      printf "* Error: Invalid arguments.*\n"
      printf "Usage: --ios=[11.4|12.4|13.3] --test=[unit|integration|ui]\n"
      exit 1
  esac
  shift
done

case "$test_env" in
    unit)         scheme="InstanaAgentTests";;
    integration)  scheme="InstanaAgentIntegrationTests";;
    ui)           scheme="InstanaAgentUITests";;
esac

echo "Running..."
case "$ios_version" in
    11)       xcodebuild test -destination 'name=iPhone X,OS=11.4' -scheme ''${scheme}'' | xcpretty;;
    12)       xcodebuild test -destination 'name=iPhone Xs Max,OS=12.4' -scheme ''${scheme}'' | xcpretty;;
    13)       xcodebuild test -destination 'name=iPhone 11 Pro Max,OS=13.3' -scheme ''${scheme}'' | xcpretty;;
esac
