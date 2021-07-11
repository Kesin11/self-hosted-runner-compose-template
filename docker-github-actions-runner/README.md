# Using myoung34/docker-github-actions-runner

## docker-compose
Launch multiple self-hosted org runner.
As a result, runners registerd Github Actions like this,

- docker-github-actions-2yDToplLsTTuy
  - self-hosted Linux X64 container
- docker-github-actions-vsWraylv1fkvK
  - self-hosted Linux X64 container
- docker-github-actions-hkInotNdxNmVa
  - self-hosted Linux X64 container


```
docker-compose up --scale worker=3
```

## kubernates
Launch multiple self-hosted org runner.

```bash
# Create namespace and secrets
kubectl create namespace runners
kubectl create secret generic -n runners runner-secret --from-literal=access-token=$GITHUB_ORG_TOKEN --from-literal=org-name=$GITHUB_ORG

# Deploy
kubectl apply -f deployment.yaml

# Watch log
kubectl logs -n runners deployment/actions-runner -
```

