#!/usr/bin/env bash
set -xe

ORG="${GITHUB_ORG}"
URL="${RUNNER_URL}"
GROUP="${RUNNER_GROUP:=Default}"
LABELS="${RUNNER_LABELS}"
WORKDIR="${RUNNER_WORKDIR:=/tmp/_work}"

# Detect container name assigned by doker-compose up --scale
HOSTNAME=$(hostname)
CONTAINER_NAME="$(sudo docker ps -f "ID=${HOSTNAME}" --format "{{.Names}}")"

# Docker outside of docker needs root user permission
export RUNNER_ALLOW_RUNASROOT=1

CONFIG_CACHE_DIR="config_cache/${CONTAINER_NAME}"

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
    --name "${CONTAINER_NAME}" \
    --runnergroup "${GROUP}" \
    --labels "${LABELS}" \
    --work "${WORKDIR}" \
    --replace

  # Store runner config to host
  sudo mkdir -p "${CONFIG_CACHE_DIR}"
  sudo cp .runner "${CONFIG_CACHE_DIR}/"
  sudo cp .credentials* "${CONFIG_CACHE_DIR}/"
  sudo cp .path "${CONFIG_CACHE_DIR}/"
  sudo cp .env "${CONFIG_CACHE_DIR}/"
fi

./run.sh --once