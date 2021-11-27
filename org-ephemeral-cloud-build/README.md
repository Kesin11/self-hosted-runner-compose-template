# Ephemeral org runner on Cloud Build

- Runner: Organization
- Runs on: Cloud Build
- Type: Container(Can use docker)
- Can use docker: Yes
- Ephemeral: Yes
- Image: https://github.com/myoung34/docker-github-actions-runner

Github Actionsのwebhookを受けてCloud Buildを起動してその中でランナーを--ephemeralで動かし、ジョブが完了したときにCloud Buildも終了終了させる。

ジョブを起動するwebhookと1対1の関係でCloud Buildを起動するのですべてのジョブは隔離された環境で実行され、必要なときに必要な並列数だけが立ち上がり、ジョブの時間分だけで完全な従量課金が実現される。

ただし、Cloud Buildの立ち上げはdocker pullから始まるため実際にランナーが立ち上がるまでに1分程度の時間がかかってしまう。そのため短時間で終わるような小さなジョブを実行する環境には向いていない。

一方でCloud Buildはオプションで8コア、32コアのマシンも起動することが可能。大規模なビルド用に強力なマシンが必要なときに必要な時間だけ立ち上げられるのは他には無い大きなメリットである。

# Cloud Buildのセットアップ
## webhookトリガー
Cloud Buildの[webhook trigger](https://cloud.google.com/build/docs/automating-builds/create-webhook-triggers)を設定する。

Githubからの `workflow_job` webhookを使用するが、`workflow_job` はジョブの起動以外に完了時などにもwebhookが飛ぶため、Cloud Build側で起動時のwebhookだけを受け取るようにフィルターを設定する。

フィルターを設定するためにはCloud Build側でペイロードを参照できるようにsubstitutionの設定が必要になるのだが、ドキュメントにあまり情報が無い。今回はこのstackoverflowを参考にした。

https://stackoverflow.com/questions/66875343/post-body-for-google-cloud-build-webhook-triggers

- `_ACTION`: `$(body.action)`
- `_LABELS`: `$(body.workflow_job.labels)`

[Filter webhook](https://cloud.google.com/build/docs/automating-builds/create-webhook-triggers)でジョブ起動時のwebhookである `action: queued` と、Cloud Buildで起動させたいラベルでフィルタリングする。

```
_ACTION.matches("queued") &&
_LABELS.matches(".*self-hosted.*") &&
_LABELS.matches(".*container.*")
```

## 認証情報とSecretManager
`ACCESS_TOKEN` などのランナーを動かすために必要なシークレットは Secret Managerに登録する必要がある。Cloud BuildからSecret Managerを参照するためには権限の追加などが必要なのでこのあたりのドキュメントを参考に設定する。

https://cloud.google.com/build/docs/securing-builds/use-secrets

## ビルド構成
[cloudbuild.yaml](./cloudbuild.yaml)をコピペしてインラインYAMLとして設定する。

`secretManager` の項目は各自のSecret Managerの設定に合わせて変更する。