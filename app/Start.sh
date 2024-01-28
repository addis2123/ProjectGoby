#!/bin/bash

# Start the first process
python receiver.py &

# Start the second process
node sender.js &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?