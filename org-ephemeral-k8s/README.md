# Ephemeral org runner on k8s

- Runner: Organization
- Runs on: k8s
- Can use docker: Yes
- Ephemeral: Yes
- Image: https://github.com/myoung34/docker-github-actions-runner

# How to recreate container when start new Github Action job
せっかく--ephemeralを付けているので、前のジョブの状態が引き継がれないようにジョブごとに新しいコンテナを立ち上げ直してほしい。

[deployment.yaml](./deployment.yaml)

k8sのDeploymentsの場合、--ephemeralを付けるとジョブが終了と同時にプロセスが終了するためk8sからは異常が発生したPodとして認識されて自動的にrestartされる。

restartされると新しいコンテナが作られるので一見すると目的は達成されているが、k8s的には異常終了されたPod扱いなので[restartの間隔はどんどん増えてしまう](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy)。


そこで、Deployments代わりに1つのプロセスが終了することが正常動作であるJobで動かすことにする。ただし、JobはDeploymentsと異なり無限にPodを作り直してくれる機能がない。 `completion` の数をものすごく増やして実質無限にするという方法はあるが、デプロイし直した場合に昔のJobが残り続けてしまう問題がある。そこでCronJobを併用する。

[job.yaml](./job.yaml)

CronJobを短い間隔で実行することで新しいJobを実質的に無限に作り続ける。デフォルトだとJobが増え続けてしまうので、 `concurrencyPolicy: forbid` にしておくことでトータルとしてのJobの数は1つに限定できる。

CronJob -> Job -> Pod(この中でself-hosted runnerが動いている)

新しくデプロイする場合CronJobが更新される。新しいCronJobがJobを作り直すことでやっと新しい設定が反映されるので1つのJobが完了する条件である `completion` はそれなりに小さな数にしておき、更新がある程度早く反映されるようにしておくといいかもしれない。
