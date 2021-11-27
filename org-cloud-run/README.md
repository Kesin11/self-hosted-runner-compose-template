# org (ephemeral) runner on Cloud Build

- Runner: Organization
- Runs on: Cloud Run
- Can use docker: Yes
- Ephemeral: No (Yesでもあるが向いていない)
- Image: https://github.com/myoung34/docker-github-actions-runner + ダミー用のPython webserverを追加

CloudRunは最近のアップデートで追加されたAlway on CPU（Preview）モードにすることでリクエストとは関係なくプロセスを動かせるのでGithub Actionsのrunnerをバックグラウンドで動かすことが可能になった。

ただし、Cloud Buildとは異なりCloud Runそのものにリクエストをフィルタリングする機能は付いていないため、必要なwebhookだけにフィルターする処理も自前で書く必要がある。

# Architecture
## Frontend
Githubからのwebhookを直接受けるwebサーバー。Githubからのwebhookのうちジョブ起動のイベントだけを抽出し、実際にランナーを動かすBackendにトラフィックを流す。

言語は何でも良い。nodejs + expressを選んだのは単に自分が得意から。

## Backend
実際にセルフホストランナーを起動するサーバー。ただしCloudRunの制約によりwebサーバーも起動させていずれかのポートをリッスンさせておく必要がある。

webサーバーは適当に200を返すだけで良いので、今回はmyoung3/docker-github-actions-runnerのイメージにインストール済みだったPython3で簡易なサーバーをバックグラウンドで動かしている。

# Deploy
frontendとbackendの2つの独自イメージが必要になるのでCloud Runから読める場所にdocker pushしておく。同じGCP内の方が簡単だろうからArtifact Registryがオススメ。

```bash
export GCP_PROJECT=$YOUR_GCP_PROJECT
export ACCESS_TOKEN=$GITHUB_RUNNER_PAT
export ORG_NAME=$YOUR_GITHUB_ORG

cd backend
docker build -t asia-northeast1-docker.pkg.dev/$GCP_PROJECT/github-actions-runner/cloudrun-backend:latest .

gcloud beta run deploy github-runner-cloudrun-backend \
  --project $GCP_PROJECT  \
  --platform managed \
  --region asia-northeast1 \
  --port 8080 \
  --cpu 1 \
  --memory 2048Mi \
  --concurrency 10 \
  --max-instances 2 \
  --min-instances 0 \
  --timeout 300 \
  --no-cpu-throttling \
  --set-env-vars RUNNER_SCOPE=org,LABELS=cloudrun,RUNNER_NAME_PREFIX=cloudrun,ORG_NAME=$ORG_NAME,ACCESS_TOKEN=$ACCESS_TOKEN \
  --image asia-northeast1-docker.pkg.dev/$GCP_PROJECT/github-actions-runner/cloudrun-backend:latest
```

デプロイ後にCloud Runから発行されるbackendのURLtendのデプロイに使用する。

```bash
export GCP_PROJECT=$YOUR_GCP_PROJECT
export BACKEND_URL=$BACKEND_CLOUDRUN_URL
cd frontend
docker build -t asia-northeast1-docker.pkg.dev/$GCP_PROJECT/github-actions-runner/cloudrun-frontend:latest .

gcloud beta run deploy github-runner-cloudrun-frontend \
  --project $GCP_PROJECT  \
  --platform managed \
  --region asia-northeast1 \
  --port 8080 \
  --cpu 1 \
  --memory 256Mi \
  --concurrency 10 \
  --max-instances 1 \
  --min-instances 0 \
  --timeout 300 \
  --set-env-vars BACKEND_URL=$BACKEND_URL,LABELS=cloudrun \
  --image asia-northeast1-docker.pkg.dev/$GCP_PROJECT/github-actions-runner/cloudrun-frontend:latest
```

デプロイ後にCloud Runから発行されるfrontendのURLをGithubのwebhookにセットする。

全体としては以下の流れでランナーが起動され、最終的にGithub ActionsのジョブがCloud Runの中で実行される。

Github Actions起動 -> `workflow_job` webhook -> frontendでフィルター -> backend起動 -> ランナーが起動してジョブが実行される


# メリット
## 起動は早い
CloudBuildに比べたメリットとしては最初からコンテナがpull済みの状態のため起動が早い。さらにMINインスタンス数を設定しておけばコールドスタート問題も解消される。

## インスタンスが残るのでローカルキャッシュも残る
CloudBuildの場合は毎回新しいVMがアサインされるのでローカルファイルは一切残らない。これはビルドとしては正しい挙動だが、一方で巨大なgitリポジトリを相手にする場合などは毎回git cloneを行うだけで相当時間がかかるので回避したい場合がある。

CloudRunでは一度起動したインスタンスはリクエストが全くなかったとしても数十分程度は維持されるようなので、キャッシュをGCSに保存するなどのテクを使わずともローカルファイルによってある程度キャッシュが効き、リクエストが来なくなったらインスタンスと共にキャッシュも破棄されるのでいい塩梅にキャッシュのクリーンも行われることになりそう。

## スペックを柔軟に選択可能
CloudBuildではスペックがせいぜい3種類しか選べなかった（プライベートプールを使う場合はもっと豊富なスペックが選べるが）一方、CloudRunではCPUとメモリをほぼ自由に組み合わせて好きなスペックにすることが可能。


# デメリット
## 構成が複雑
Githubの `workflow_job` のwebhookはジョブが起動されたときのqueued以外に終了時にcompletedなどのwebhookも飛んでいる。CloudBuildにはフィルター機能が存在していたのでqueuedのイベントのみを扱うことができたが、CloudRunにはリクエストを受ける前にフィルターする機能が存在しない。

無駄にリクエストを受けすぎてしまうとCloudRunのオートスケーリングが過剰に働いてしまい、本来必要なコンテナ数よりも過剰に起動してしまうと思われる。

そのため、自前でフィルター処理を書くためのFrontendのCloudRunも用意して、Frontend-Backendの2段構成になっている。

## ジョブの中でdockerが使えない
CloudRunではホストマシンのdockerソケットを使うことができないため、Github Actionsの中で `docker` コマンドを使うことができない（エラーになる） 

## ダミーのwebサーバーを立てる必要がある
CloudRunの制約上、実際には使う必要がなかったとしてもいずれかのポートをリッスンするプロセスを動かす必要がある。

今回はPython3で200を返すだけのサーバーをバックグラウンドで動かすことでこの制約を満たしているが、無駄は無駄である。

## ephemeralが向かない
--ephemeralでの起動を試したところ、1ジョブを完了するとコンテナが終了し、実際にCloudRun上でも課金されるコンテナ数からはカウントされなくなるようである。k8sのDeploymentでは異常終了とみなされてrestart時間が次第に長くなる問題が存在したが、CloudRunではそのようなデメリットはおそらく無いように見える。

ただ、CloudBuildではwebhookと立ち上がるランナーの関係が1:1だったのに対して、CloudRunではN:1になる。従って、CloudRun上で全てのephemeralなランナーがジョブを完了した判定をしたとしても実際にはGithub Actions上のジョブはまだキューに残ったままという状況が発生することがある。

対策としてはephemeralでの運用をやめるか、あるいはMINインスタンス数を最低でも1は確保しておく方法が考えられる。

ephemeralの運用を諦めればCPUが仕事をしている限り（=ジョブがキューに残っている状態）はインスタンスの数がゼロにされないと思われる（CloudRunの仕様にそこまで詳しくはないので自信はない）。一方で夜間のように全くジョブが実行されない時間がある程度続けば最小で0インスタンスまでスケールダウンしてくれる。

ephemeralを諦めない場合はMINインスタンス数を0ではなく1以上にしておくとことで最低限1つのランナーは動いている状態を維持できるので、キューのジョブが全く実行されないという状態は回避できるはず。

# まとめ
CloudBuildに比べてコールドスタートであったとしても起動が早いため、Github上のラベルを操作するなどのAPIを叩くだけの軽いジョブには向いている。

一方でちゃんとしたビルドをするジョブの場合はdockerを使えないことがかなりの罠であったり、webhookのフィルタリングを自作する必要があったりするところが割と面倒である。

総括すると、どんなに軽いジョブでも1分程度のスタートアップ時間を許容できるのであればCloud Buildの方が簡単。軽いジョブなら素早く起動したいというニーズが強いのであれば頑張ってCloud Runにするか併用すると良い。