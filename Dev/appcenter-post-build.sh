#!/usr/bin/env bash

# Post Build Script
set -e # Exit immediately if a command exits with a non-zero status (failure)

echo "***************************"
echo "Start Swift Package Tests"
echo "***************************"

if [ "$AGENT_JOBSTATUS" == "Succeeded" ]; then
	cd ..
	sh run-swiftpm-tests.sh
fi
