# Github Actions self-hosted runner template
Template of various how to deploy Github Actions self-hosted runner.

# [Docker](./org-ephemeral-docker)
Deploy to some machine that docker is installed. This is the most simple way, but not practical.

# [k8s](./org-ephemeral-k8s)
Deploy to k8s as simple `CronJob'.

# [Cloud Build](./org-ephemeral-cloud-build)
Deploy to GCP Cloud Build. It also needs Github `worflow_jobs` webhook.

# [Cloud Run](./org-cloud-run)
Deploy to GCP Cloud Run. It also needs Github `workflow_jobs` webhook.
