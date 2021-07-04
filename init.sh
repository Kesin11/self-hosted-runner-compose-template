#!/usr/bin/env bash

URL="${RUNNER_URL}"
TOKEN="${RUNNER_TOKEN}"
NAME="${RUNNER_NAME}"
GROUP="${RUNNER_GROUP:=Default}"
LABELS="${RUNNER_LABELS}"
WORKDIR="${RUNNER_WORKDIR:=_work}"

./config.sh \
  --unattended \
  --url "${URL}" \
  --token "${TOKEN}" \
  --name "${NAME}" \
  --runnergroup "${GROUP}" \
  --labels "${LABELS}" \
  --work "${WORKDIR}" \
  --replace

./run.sh --once