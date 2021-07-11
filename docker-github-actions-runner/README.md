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