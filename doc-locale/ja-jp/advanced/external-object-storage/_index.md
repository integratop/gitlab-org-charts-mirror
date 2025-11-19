---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部オブジェクトストレージでGitLabチャートを設定する
---

GitLabは、Kubernetesで可用性の高い永続データをオブジェクトストレージに依存しています。GitLabは、主要なクラウドプロバイダーのオブジェクトストレージに対して、静的な認証情報と、クラウド固有のサービスを介した一時的な認証情報という2種類の認証方法をサポートしています。

## 静的な認証情報 {#static-credentials}

これらの認証情報は、すべてのプロバイダーに対して有効期間の長いアクセスキーとシークレットです:

- AWS S3: アクセスキーID + クライアントのシークレットキー
- Google Cloud Storage: サービスアカウントJSONキーファイル
- Azure Blob Storage: ストレージアカウント名 + アクセスキー、またはクライアントID + テナントID + クライアントシークレット

## Cloud IAMを介した一時的な認証情報 {#temporary-credentials-through-cloud-iam}

GitLabは、動的な有効期間の短い認証情報のために、プロバイダー固有のワークロードIDメカニズムを取得できます:

- AWS S3: [サービスアカウント用IAMロール（IRSA）](aws-iam-roles.md)
- Google Cloud Storage: [ワークロードアイデンティティフェデレーション](gke-workload-identity.md)。
- Azure Blob Storage: [Azure Kubernetes ServiceのワークロードID](azure-workload-identity.md)

これらの一時的な認証情報メカニズムは、以下によりセキュリティを向上させます:

- 有効期間の長い静的な認証情報を排除します。
- 自動化された認証情報のローテーションを提供します。
- きめ細かいアクセス制御
- 認証情報の使用状況の監査ログをサポートします。
- クラウドプロバイダーのIAMポリシーと統合します。

## MinIOの無効化 {#disable-minio}

デフォルトでは、`minio`という名前のS3互換ストレージソリューションがチャートとともにデプロイされます。本番環境品質のデプロイの場合、Google Cloud StorageやAWS S3などのホストされているオブジェクトストレージソリューションを使用することをお勧めします。

MinIOを無効にするには、このオプションを設定し、以下の関連ドキュメントに従ってください:

```shell
--set global.minio.enabled=false
```

[完全な設定の例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml)が[例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples)に記載されています。

## Azure Blob Storage {#azure-blob-storage}

Azure BLOBストレージのダイレクトサポートは、[アップロードされた添付ファイル、CIジョブアーティファクト、LFS、および統合された設定を介してサポートされるその他のオブジェクトタイプ](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration)で利用できます。以前のGitLabのバージョンでは、[Azure MinIOゲートウェイ](azure-minio-gateway.md)が必要でした。

{{< alert type="note" >}}

GitLabは、DockerレジストリのストレージとしてAzure MinIOゲートウェイを[サポートしていません](https://github.com/minio/minio/issues/9978)。[対応するAzureの例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)を、[Dockerレジストリの設定](#docker-registry-images)時に参照してください。

{{< /alert >}}

Azureではコンテナのコレクションを表す用語としてを使用していますが、GitLabではこの用語をバケットに標準化しています。

Azure BLOBストレージでは、[統合されたオブジェクトストレージの設定](../../charts/globals.md#consolidated-object-storage)を使用する必要があります。1つのAzureストレージアカウント名とキーを、複数のAzure BLOBコンテナで使用する必要があります。オブジェクトタイプ（`artifacts`アーティファクト、`uploads`アップロードなど）による個々の`connection`設定のカスタマイズは許可されていません。

Azure BLOBストレージを有効にするには、Azure `connection`を定義する例として[`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)を参照してください。これは、以下のようにシークレットとして読み込むことができます:

```shell
kubectl create secret generic gitlab-rails-storage --from-file=connection=rails.azurerm.yml
```

次に、MinIOを無効にして、これらのグローバル設定を設定します:

```shell
--set global.minio.enabled=false
--set global.appConfig.object_store.enabled=true
--set global.appConfig.object_store.connection.secret=gitlab-rails-storage
```

[デフォルト名またはバケット設定でコンテナ名を設定](../../charts/globals.md#specify-buckets)するために、Azureコンテナを作成してください。

{{< alert type="note" >}}

`Requests to the local network are not allowed`でリクエストが失敗する場合は、[トラブルシューティング](#troubleshooting)のセクションを参照してください。

{{< /alert >}}

## Dockerレジストリイメージ {#docker-registry-images}

`registry`チャートのオブジェクトストレージの設定は、`registry.storage`キーと、`global.registry.bucket`キーを介して行われます。

```shell
--set registry.storage.secret=registry-storage
--set registry.storage.key=config
--set global.registry.bucket=bucket-name
```

{{< alert type="note" >}}

バケット名は、シークレットと`global.registry.bucket`の両方で設定する必要があります。そのシークレットはレジストリサーバーで使用され、グローバル変数はGitLabのバックアップで使用されます。

{{< /alert >}}

[ストレージに関するレジストリチャートのドキュメント](../../charts/registry/_index.md#storage)ごとにシークレットを作成し、このシークレットを使用するようにチャートを設定します。

[S3](https://distribution.github.io/distribution/storage-drivers/s3/) （S3互換のストレージですが、Azure MinIOゲートウェイはサポートされていません。[Azure BLOBストレージ](#azure-blob-storage)を参照）、[Azure](https://distribution.github.io/distribution/storage-drivers/azure/) 、[GCS](https://distribution.github.io/distribution/storage-drivers/gcs/)ドライバーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります。

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)
- [`registry.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)

### レジストリの設定 {#registry-configuration}

1. 使用するストレージサービスを決定します。
1. 適切なファイルを`registry-storage.yaml`にコピーします。
1. 環境に適した値で編集します。
1. シークレットを作成するには、[ストレージに関するレジストリチャートのドキュメント](../../charts/registry/_index.md#storage)に従ってください。
1. ドキュメントの説明に従ってチャートを設定します。

## LFS、アーティファクト、アップロード、パッケージ、外部差分、Terraformステート、依存プロキシ、セキュアファイル {#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files}

LFS、アーティファクト、アップロード、パッケージ、外部差分、Terraformステート、セキュアファイル、および仮名化子のオブジェクトストレージの設定は、次のキーを介して行われます:

- `global.appConfig.lfs`
- `global.appConfig.artifacts`
- `global.appConfig.uploads`
- `global.appConfig.packages`
- `global.appConfig.externalDiffs`
- `global.appConfig.dependencyProxy`
- `global.appConfig.terraformState`
- `global.appConfig.ciSecureFiles`

次の点にも注意してください:

- [バケット設定でデフォルト名またはカスタム名](../../charts/globals.md#specify-buckets)のバケットを作成する必要があります。
- それぞれに異なるバケットが必要です。そうしないと、バックアップからの復元が正常に機能しません。
- 外部ストレージへのMR差分の保存はデフォルトでは有効になっていないため、`externalDiffs`のオブジェクトストレージ設定を有効にするには、`global.appConfig.externalDiffs.enabled`キーに`true`の値が必要です。
- 依存プロキシ機能はデフォルトで有効になっていないため、`dependencyProxy`のオブジェクトストレージ設定を有効にするには、`global.appConfig.dependencyProxy.enabled`キーに`true`の値が必要です。

以下は、設定オプションの例です:

```shell
--set global.appConfig.lfs.bucket=gitlab-lfs-storage
--set global.appConfig.lfs.connection.secret=object-storage
--set global.appConfig.lfs.connection.key=connection

--set global.appConfig.artifacts.bucket=gitlab-artifacts-storage
--set global.appConfig.artifacts.connection.secret=object-storage
--set global.appConfig.artifacts.connection.key=connection

--set global.appConfig.uploads.bucket=gitlab-uploads-storage
--set global.appConfig.uploads.connection.secret=object-storage
--set global.appConfig.uploads.connection.key=connection

--set global.appConfig.packages.bucket=gitlab-packages-storage
--set global.appConfig.packages.connection.secret=object-storage
--set global.appConfig.packages.connection.key=connection

--set global.appConfig.externalDiffs.bucket=gitlab-externaldiffs-storage
--set global.appConfig.externalDiffs.connection.secret=object-storage
--set global.appConfig.externalDiffs.connection.key=connection

--set global.appConfig.terraformState.bucket=gitlab-terraform-state
--set global.appConfig.terraformState.connection.secret=object-storage
--set global.appConfig.terraformState.connection.key=connection

--set global.appConfig.dependencyProxy.bucket=gitlab-dependencyproxy-storage
--set global.appConfig.dependencyProxy.connection.secret=object-storage
--set global.appConfig.dependencyProxy.connection.key=connection

--set global.appConfig.ciSecureFiles.bucket=gitlab-ci-secure-files
--set global.appConfig.ciSecureFiles.connection.secret=object-storage
--set global.appConfig.ciSecureFiles.connection.key=connection
```

詳細については、[アプリ設定に関するチャートのグローバルドキュメント](../../charts/globals.md#configure-appconfig-settings)を参照してください。

[接続の詳細ドキュメント](../../charts/globals.md#connection)ごとにシークレットを作成し、提供されたシークレットを使用するようにチャートを設定します。同じシークレットをすべてに使用できます。

[AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog) （[MinIOを使用したAzure](azure-minio-gateway.md)のようなS3互換）および[Google](https://fog.github.io/storage/#google-cloud-storage)プロバイダーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります。

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azure.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)

### S3暗号化 {#s3-encryption}

GitLabは、[S3バケットに保存されているデータを暗号化する](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)ために[Amazon KMS](https://aws.amazon.com/kms/)をサポートしています。これは、次の2つの方法で有効にできます:

- AWSで、[デフォルトの暗号化を使用するようにS3バケットを設定します](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)。
- GitLabで、[サーバーサイド暗号化ヘッダーを有効にします。](../../charts/globals.md#storage_options)

これら2つのオプションは相互に排他的ではありません。デフォルトの暗号化ポリシーを設定できますが、オーバーライドするためにサーバーサイド暗号化ヘッダーを有効にすることもできます。

詳細については、[暗号化されたS3バケットに関するGitLabドキュメント](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)を参照してください。

### アプリ設定の設定 {#appconfig-configuration}

1. 使用するストレージサービスを決定します。
1. 適切なファイルを`rails.yaml`にコピーします。
1. 環境に適した値で編集します。
1. シークレットを作成するには、[接続の詳細ドキュメント](../../charts/globals.md#connection)に従ってください。
1. ドキュメントの説明に従ってチャートを設定します。

## バックアップ {#backups}

バックアップはオブジェクトストレージにも保存されており、含まれているMinIOサービスではなく、外部を指すように設定する必要があります。バックアップ/復元手順では、2つの異なるバケットを使用します:

- バックアップを保存するためのバケット（`global.appConfig.backups.bucket`）
- 復元プロセス中に既存のデータを保持するための一時バケット（`global.appConfig.backups.tmpBucket`）

AWS S3互換のオブジェクトストレージシステム、Google Cloud Storage、およびAzure BLOBストレージがサポートされているバックエンドです。`global.appConfig.backups.objectStorage.backend`をAWS S3の場合は`s3`、Google Cloud Storageの場合は`gcs`、Azure BLOBストレージの場合は`azure`に設定して、バックエンドタイプを設定できます。`gitlab.toolbox.backups.objectStorage.config`キーを使用して、接続設定も指定する必要があります。

シークレットでGoogle Cloud Storageを使用する場合、GCPプロジェクトは`global.appConfig.backups.objectStorage.config.gcpProject`値で設定する必要があります。

S3互換ストレージの場合:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

シークレットを使用したGoogle Cloud Storage（GCS）の場合:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
--set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

[GKEのワークロードアイデンティティフェデレーション](gke-workload-identity.md)を使用したGoogle Cloud Storage（GCS）の場合、バックエンドとバケットのみを設定する必要があります。`gitlab.toolbox.backups.objectStorage.config.secret`と`gitlab.toolbox.backups.objectStorage.config.key`が設定されていないことを確認して、クラスターが[Googleのアプリケーションのデフォルト認証情報](https://cloud.google.com/docs/authentication/application-default-credentials)を使用するようにします:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
```

🟢 Azure Blob Storage:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=azure
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

詳細については、[バックアップ/復元オブジェクトストレージのドキュメント](../../backup-restore/_index.md#object-storage)を参照してください。

{{< alert type="note" >}}

他のオブジェクトストレージロケーションからファイルをバックアップまたは復元するには、すべてのGitLabのバケットに対する読み取り/書き込みを行うのに十分なアクセス権を持つユーザーとして認証するように、設定ファイルを設定する必要があります。

{{< /alert >}}

### バックアップストレージの例 {#backups-storage-example}

1. `storage.config`ファイルを作成する:

   - Amazon S3では、コンテンツは[s3cmd設定ファイル形式](https://s3tools.org/kb/item14.htm)にする必要があります

     ```ini
     [default]
     access_key = AWS_ACCESS_KEY
     secret_key = AWS_SECRET_KEY
     bucket_location = us-east-1
     multipart_chunk_size_mb = 128 # default is 15 (MB)
     ```

   - Google Cloud Storageでは、`storage.admin`ロールを持つサービスアカウントを作成し、[サービスアカウントキーを作成する](https://cloud.google.com/iam/docs/keys-create-delete#creating_service_account_keys)ことでファイルを作成できます。以下は、`gcloud` CLIを使用してファイルを作成する例です。

     ```shell
     export PROJECT_ID=$(gcloud config get-value project)
     gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
     gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
     gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
     ```

   - Azureストレージ上

     ```ini
     [default]
     # Setup endpoint: hostname of the Web App
     host_base = https://your_minio_setup.azurewebsites.net
     host_bucket = https://your_minio_setup.azurewebsites.net
     # Leave as default
     bucket_location = us-west-1
     use_https = True
     multipart_chunk_size_mb = 128 # default is 15 (MB)

     # Setup access keys
     # Access Key = Azure Storage Account name
     access_key = AZURE_ACCOUNT_NAME
     # Secret Key = Azure Storage Account Key
     secret_key = AZURE_ACCOUNT_KEY

     # Use S3 v4 signature APIs
     signature_v2 = False
     ```

1. シークレットを作成する

   ```shell
   kubectl create secret generic storage-config --from-file=config=storage.config
   ```

## Google Cloud CDN {#google-cloud-cdn}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98010)。

{{< /history >}}

[Google CDN](https://cloud.google.com/cdn)を使用して、アーティファクトバケットからデータをキャッシュし、フェッチできます。これは、パフォーマンスを向上させ、ネットワークエグレスコストを削減するのに役立ちます。

CDNの設定は、次のキーを介して行われます:

- `global.appConfig.artifacts.cdn.secret`
- `global.appConfig.artifacts.cdn.key`（デフォルトは`cdn`です）

CDNを使用するには:

1. [アーティファクトバケットをバックエンドとして使用するように、CDNを設定](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)します。
1. [署名付きURLのキーを作成](https://cloud.google.com/cdn/docs/using-signed-urls)します。
1. [バケットから読み取りを行う権限をCDNサービスアカウントに付与](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions)します。
1. [`rails.googlecdn.yaml`の例を使用して、パラメータを含むYAMLファイルを用意します](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/cdn/rails.googlecdn.yaml)。次の情報を入力する必要があります:
   - `url`: 手順1からのCDNホストのベースURL
   - `key_name`: 手順2からのキー名
   - `key`: 手順2からの実際のシークレット
1. このYAMLファイルを、`cdn`キーの下のKubernetesシークレットに読み込むします。たとえば、`gitlab-rails-cdn`シークレットを作成するには:

   ```shell
   kubectl create secret generic gitlab-rails-cdn --from-file=cdn=rails.googlecdn.yml
   ```

1. `global.appConfig.artifacts.cdn.secret`を`gitlab-rails-cdn`に設定します。`helm`パラメータを使用してこれを設定する場合は、次を使用します:

    ```shell
    --set global.appConfig.artifacts.cdn.secret=gitlab-rails-cdn
    ```

## トラブルシューティング {#troubleshooting}

### Azure BLOB: `URL [FILTERED] is blocked: Requests to the local network are not allowed` {#azure-blob-url-filtered-is-blocked-requests-to-the-local-network-are-not-allowed}

これは、Azure BLOBホスト名が[RFC1918（ローカル/プライベート）IPアドレス](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints)に解決される場合に発生します。回避策として、Azure BLOBホスト名（`yourinstance.blob.core.windows.net`）の[送信](https://docs.gitlab.com/security/webhooks/#allowlist-for-local-requests)リクエストを許可します。
