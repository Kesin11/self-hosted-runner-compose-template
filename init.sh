#!/usr/bin/env bash
set -xe

ORG="${GITHUB_ORG}"
URL="${RUNNER_URL}"
NAME="${RUNNER_NAME}"
GROUP="${RUNNER_GROUP:=Default}"
LABELS="${RUNNER_LABELS}"
WORKDIR="${RUNNER_WORKDIR:=/tmp/_work}"

CONFIG_CACHE_DIR="config_cache"

# Restore runner config from host
if [ ! -z "$(ls -A ${CONFIG_CACHE_DIR})" ]; then
  sudo cp "${CONFIG_CACHE_DIR}/.runner" ./
  sudo cp "${CONFIG_CACHE_DIR}/.credentials" ./
  sudo cp "${CONFIG_CACHE_DIR}/.credentials_rsaparams" ./
  sudo chmod +r ".credentials_rsaparams"
  sudo cp "${CONFIG_CACHE_DIR}/.path" ./
  sudo cp "${CONFIG_CACHE_DIR}/.env" ./
fi

if [ ! -e ".runner" ]; then
  RUNNER_TOKEN="$(GITHUB_TOKEN=${GITHUB_ORG_TOKEN} gh api -X POST orgs/${ORG}/actions/runners/registration-token | jq -r .token)"
  ./config.sh \
    --unattended \
    --url "${URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${NAME}" \
    --runnergroup "${GROUP}" \
    --labels "${LABELS}" \
    --work "${WORKDIR}" \
    --replace

  # Store runner config to host
  sudo cp .runner "${CONFIG_CACHE_DIR}/"
  sudo cp .credentials* "${CONFIG_CACHE_DIR}/"
  sudo cp .path "${CONFIG_CACHE_DIR}/"
  sudo cp .env "${CONFIG_CACHE_DIR}/"
fi

./run.sh --once