if [ "$AGENT_JOBSTATUS" == "Succeeded" ]; then
	cd ..
	sh run-swiftpm-tests.sh
fi
