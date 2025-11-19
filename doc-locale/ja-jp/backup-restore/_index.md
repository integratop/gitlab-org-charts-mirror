---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインスタンスのバックアップとリストア
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Helmチャートは、GitLabインスタンスをバックアップおよびリストアする目的で、インターフェースとして機能するToolboxサブチャートからユーティリティポッドを提供します。このタスクに必要な他のポッドとやり取りする`backup-utility`実行可能ファイルが搭載されています。ユーティリティの動作方法に関する技術的な詳細は、[アーキテクチャドキュメント](../architecture/backup-restore.md)に記載されています。

## 前提要件 {#prerequisites}

- ここに記載されているバックアップとリストアの手順は、S3互換APIでのみテストされています。Google Cloud Storageなどの他のオブジェクトストレージサービスのサポートは、今後のリビジョンでテストされる予定です。

- リストア中、バックアップtarballをディスクに展開する必要があります。つまり、Toolboxポッドには、[必要なサイズのディスク](../charts/gitlab/toolbox/_index.md#restore-considerations)が必要です。

- このチャートは、`artifacts`、`uploads`、`packages`、`registry`、`lfs`オブジェクトに[オブジェクトストレージ](#object-storage)を使用しており、リストア中にこれらを移行することはありません。別のインスタンスから取得したバックアップをリストアする場合は、バックアップを実行する前に、既存のインスタンスをオブジェクトストレージを使用するように移行する必要があります。[issue 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)を参照してください。

## バックアップとリストアの手順 {#backup-and-restoring-procedures}

- [GitLabインストールのバックアップ](backup.md)
- [GitLabインストールのリストア](restore.md)

## オブジェクトストレージ {#object-storage}

[外部オブジェクトストレージ](../advanced/external-object-storage/_index.md)が指定されていない限り、このチャートを使用すると、すぐにMinIOインスタンスが提供されます。特定の設定が行われていない限り、Toolboxはデフォルトで含まれているMinIOに接続します。Toolboxは、Amazon S3またはGoogle Cloud Storage（GCS）にバックアップするように設定することもできます。

### S3へのバックアップ {#backups-to-s3}

別のS3ツールを使用するように指定しない限り、Toolboxはデフォルトで`s3cmd`を使用してオブジェクトストレージに接続します[。](backup.md#specify-s3-tool-to-use)外部オブジェクトストレージへの接続を構成するには、`gitlab.toolbox.backups.objectStorage.config.secret`ファイルを格納するKubernetesシークレットを指す`.s3cfg`を指定する必要があります。`config`のデフォルトと異なる場合は、`gitlab.toolbox.backups.objectStorage.config.key`を指定する必要があります。これは、[`.s3cfg`](https://s3tools.org/kb/item14.htm)ファイルの内容を含むキーを指します。

このようになります:

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=my-s3cfg \
  --set gitlab.toolbox.backups.objectStorage.config.key=config .
```

さらに、2つのバケットの場所を構成する必要があります。バックアップを格納するための場所と、バックアップのリストア時に使用される一時バケットです。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

### Google Cloud Storage（GCS）へのバックアップ {#backups-to-google-cloud-storage-gcs}

GCSにバックアップするには、まず`gitlab.toolbox.backups.objectStorage.backend`を`gcs`に設定する必要があります。これにより、オブジェクトの格納と取得を行うときに、Toolboxが`gsutil` CLIを使用するようになります。

さらに、2つのバケットの場所を構成する必要があります。バックアップを格納するための場所と、バックアップのリストア時に使用される一時バケットです。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

バックアップユーティリティは、これらのバケットにアクセスする必要があります。アクセスを許可する方法は2つあります:

- Kubernetesシークレットで認証情報を指定します。
- GKEの[ワークロードID連携](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)を構成します。

#### GCS認証情報 {#gcs-credentials}

まず、`gitlab.toolbox.backups.objectStorage.config.gcpProject`を、ストレージバケットを含むGCPプロジェクトのプロジェクトIDに設定します。

バックアップに使用するバケットの`storage.admin`ロールを持つサービスアカウントがアクティブなサービスアカウントJSONキーの内容を含むKubernetesシークレットを作成する必要があります。次に、シークレットを作成するために`gcloud`と`kubectl`を使用する例を示します。

```shell
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
kubectl create secret generic storage-config --from-file=config=storage.config
```

バックアップ用にGCSへの認証をサービスアカウントキーで行うには、Helmチャートを次のように設定します:

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=storage-config \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id \
  --set gitlab.toolbox.backups.objectStorage.backend=gcs
```

#### GKEのワークロードID連携の設定 {#configuring-workload-identity-federation-for-gke}

[GitLabチャートを使用したGKEのワークロードID連携に関するドキュメント](../advanced/external-object-storage/gke-workload-identity.md)を参照してください。

Kubernetes ServiceAccountを参照するIAM許可ポリシーを作成する場合は、`roles/storage.objectAdmin`ロールを付与します。

バックアップの場合、`gitlab.toolbox.backups.objectStorage.config.secret`、`gitlab.toolbox.backups.objectStorage.config.key`、`gitlab.toolbox.backups.objectStorage.config.gcpProject`が設定されていないことを確認して、Googleのアプリケーションデフォルト認証情報が使用されていることを確認します。

### Azure BLOBストレージへのバックアップ {#backups-to-azure-blob-storage}

`gitlab.toolbox.backups.objectStorage.backend`を`azure`に設定すると、Azure BLOBストレージにバックアップを格納するためにAzure BLOBストレージを使用できます。これにより、Toolboxは、含まれている`azcopy`のコピーを使用して、バックアップファイルをAzure BLOBストレージに送信および取得できます。

Azure BLOBストレージを使用するには、既存のリソースグループにストレージアカウントを作成する必要があります。ストレージアカウントの名前、アクセスキー、BLOBホストを使用して、設定ファイルシークレットを作成します。

パラメータを含む設定ファイルを作成します:

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_access_key: <access key value>
azure_storage_domain: blob.core.windows.net # optional
```

次の`kubectl`コマンドを使用して、Kubernetesシークレットを作成できます:

```shell
kubectl create secret generic backup-azure-creds \
  --from-file=config=azure-backup-conf.yaml
```

シークレットが作成されると、デプロイされた値にバックアップ設定を追加するか、Helmコマンドラインで設定を指定することにより、GitLab Helmチャートを構成できます。例: 

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=backup-azure-creds \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.backend=azure
```

シークレットからのアクセスキーは、ストレージアカウントにアクセスするために、より短い期間の共有アクセス署名（SAS）トークンを生成および更新するために使用されます。

さらに、2つのバケット/コンテナを事前に作成する必要があります。バックアップを格納するためのコンテナと、バックアップのリストア時に使用される一時バケットです。値または設定にバケット名を追加します。例: 

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

## トラブルシューティング {#troubleshooting}

### ポッドの削除イシュー {#pod-eviction-issues}

バックアップはオブジェクトストレージターゲットの外部でローカルにアセンブルされるため、一時的なディスク容量が必要です。必要なスペースは、実際のバックアップアーカイブのサイズを超える可能性があります。デフォルトの設定では、Toolboxポッドのファイルシステムを使用して一時データを格納します。ポッドのリソース不足によりポッドが削除された場合は、一時データを保持するために永続ボリュームをポッドにアタッチする必要があります。GKEで、次の設定をHelmコマンドに追加します:

```shell
--set gitlab.toolbox.persistence.enabled=true
```

バックアップが、含まれているバックアップcronジョブの一部として実行されている場合は、cronジョブの永続性を有効にすることをお勧めします:

```shell
--set gitlab.toolbox.backups.cron.persistence.enabled=true
```

他のプロバイダーの場合は、永続ボリュームを作成する必要がある場合があります。これを行う方法の例については、[ストレージドキュメント](../installation/storage.md)を参照してください。

### 「バケットが見つかりません」というエラー {#bucket-not-found-errors}

バックアップ中に`Bucket not found`エラーが表示される場合は、バケットの認証情報が構成されていることを確認してください。

コマンドは、クラウドストレージサービスプロバイダーによって異なります:

- AWS S3の場合、認証情報は`~/.s3cfg`のToolboxポッドに格納されます。以下を実行します:

  ```shell
  s3cmd ls
  ```

- GCP GCSの場合は、次を実行します:

  ```shell
  gsutil ls
  ```

使用可能なバケットのリストが表示されます。

### 「AccessDeniedException: GCPでの403」エラー {#accessdeniedexception-403-errors-in-gcp}

通常、GitLabインスタンスのバックアップまたはリストア中に`[Error] AccessDeniedException: 403 <GCP Account> does not have storage.objects.list access to the Google Cloud Storage bucket.`のようなエラーが発生します。認証情報がないためです。

バックアップおよびリストア操作は環境内のすべてのバケットを使用するため、環境内のすべてのバケットが作成されていること、およびGCPアカウントがすべてのバケットにアクセス（リスト、読み取り、書き込み）できることを確認します:

1. Toolboxポッドを見つけます:

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. ポッドの環境内のすべてのバケットを取得します。`<toolbox-pod-name>`を実際のToolboxポッド名に置き換えますが、`"BUCKET_NAME"`はそのままにします:

   ```shell
   kubectl describe pod <toolbox-pod-name> | grep "BUCKET_NAME"
   ```

1. 環境内のすべてのバケットへのアクセス権があることを確認します:

   ```shell
   # List
   gsutil ls gs://<bucket-to-validate>/

   # Read
   gsutil cp gs://<bucket-to-validate>/<object-to-get> <save-to-location>

   # Write
   gsutil cp -n <local-file> gs://<bucket-to-validate>/
   ```

### 「ERROR: `/home/git/.s3cfg`: None」エラーが、`--backend s3`を指定して`backup-utility`を実行する際に発生する {#error-homegits3cfg-none-error-when-running-backup-utility-with---backend-s3}

このエラーは、`.s3cfg`ファイルを含むKubernetesシークレットが`gitlab.toolbox.backups.objectStorage.config.secret`値を介して指定されていない場合に発生します。

これを修正するには、[S3へのバックアップ](_index.md#backups-to-s3)の手順に従ってください。

### 「PermissionError: S3を使用した「ファイルが書き込み可能ではありません」というエラー {#permissionerror-file-not-writable-errors-using-s3}

Toolboxユーザーが、バケットアイテムの格納されている権限と一致するファイルを書き込む権限を持っていない場合、`[Error] WARNING: <file> not writable: Operation not permitted`のようなエラーが発生します。

これを防ぐには、`gitlab.toolbox.backups.objectStorage.config.secret`を介して参照される`.s3cfg`ファイルに次のフラグを追加して、ファイルオーナー、モード、タイムスタンプを保持しないように`s3cmd`を構成します。

```toml
preserve_attrs = False
```

### リストア時にスキップされたリポジトリ {#repositories-skipped-on-restore}

GitLab 16.6/Chart 7.6以降では、バックアップアーカイブの名前が変更された場合、リストア時にリポジトリがスキップされる場合があります。これを回避するには、バックアップアーカイブの名前を変更せず、バックアップの名前を元の名前に変更します（`{backup_id}_gitlab_backup.tar`）。

元のバックアップIDは、リポジトリバックアップディレクトリ構造から抽出できます: `repositories/@hashed/*/*/*/{backup_id}/LATEST`
