#!/bin/bash
set -o pipefail

scheme='InstanaAgentTests'

while [ $# -gt 0 ]; do
  case "$1" in
    --ios=*)
      ios_version="${1#*=}"
      ;;
    *)
      printf "* Error: Invalid arguments.*\n"
      printf "Usage: --ios=[11|12|13|14]\n"
      exit 1
  esac
  shift
done


echo "Running..."
case "$ios_version" in
    11)       xcodebuild test -destination 'name=iPhone X,OS=11.1' -scheme ''${scheme}'' | xcpretty "--color";;
    12)       xcodebuild test -destination 'name=iPhone Xs Max,OS=12.4' -scheme ''${scheme}'' | xcpretty "--color";;
    13)       xcodebuild test -destination 'name=iPhone 11 Pro Max,OS=13.5' -scheme ''${scheme}'' | xcpretty "--color";;
    14)       xcodebuild test -destination 'name=iPhone 12 Pro Max,OS=14.5' -scheme ''${scheme}'' | xcpretty "--color";;
    *)  echo "iOS $ios_version not defined yet"
esac
