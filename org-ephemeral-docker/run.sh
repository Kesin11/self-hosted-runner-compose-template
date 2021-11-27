#!/usr/bin/env bash

# docker run -d --restart always --name github-runner \
docker run --rm --name github-runner \
  -e RUNNER_NAME_PREFIX="ephemeral-docker" \
  -e ACCESS_TOKEN="${RUNNER_PAT}" \
  -e RUNNER_SCOPE="org" \
  -e ORG_NAME="${ORG}" \
  -e LABELS="container" \
  -e EPHEMERAL=1 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  myoung34/github-runner:latest
