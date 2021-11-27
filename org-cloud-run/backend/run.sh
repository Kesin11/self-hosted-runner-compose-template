#!/usr/bin/dumb-init /bin/bash

# Run dummy web server in background for Cloud Run
python3 /server.py &

# Invoke myoung34/github-runner default entrypoint.sh
/entrypoint.sh $@