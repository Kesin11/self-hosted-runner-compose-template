# self-hosted-runner-compose-template
A template running GitHub Actions self hosted runner with docker-compose

# USAGE
```
export GITHUB_ORG_TOKEN=$GITHUB_ORG_TOKEN
export GITHUB_ORG=$GITHUB_ORG
export RUNNER_URL=$RUNNER_URL

docker-compose up --build -d --scale runner=2
```