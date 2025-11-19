---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインストールのバックアップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabのバックアップは、チャートで提供されるToolboxポッドで`backup-utility`コマンドを実行することで取得されます。バックアップは、このチャートの[Cron based backup](#cron-based-backup)機能を有効にすることで自動化することもできます。

初めてバックアップを実行する前に、[オブジェクトストレージ](_index.md#object-storage)へのアクセスを許可するように[Toolboxが適切に設定されている](../charts/gitlab/toolbox/_index.md#configuration)ことを確認する必要があります。

GitLab Helmチャートベースのインストールをバックアップするには、以下の手順に従ってください。

## バックアップを作成します {#create-the-backup}

1. 次のコマンドを実行して、toolboxポッドが実行されていることを確認します。

   ```shell
   kubectl get pods -lrelease=<release_name>,app=toolbox
   ```

   `<release_name>`をHelmリリースの名前に置き換えます。通常は`gitlab`です。

1. バックアップユーティリティを実行します

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility
   ```

1. オブジェクトストレージサービスの`gitlab-backups`バケットにアクセスし、tarballが追加されていることを確認します。`<backup_ID>_gitlab_backup.tar`形式で命名されます。[バックアップ](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)についてお読みください。

1. このtarballは復元に必要です。

## Cronベースのバックアップ {#cron-based-backup}

{{< alert type="note" >}}

Helmチャートによって作成されたKubernetes CronJobは、jobTemplateに`cluster-autoscaler.kubernetes.io/safe-to-evict: "false"`注釈を設定します。GKE Autopilotなど、一部のKubernetes環境では、この注釈を設定できず、バックアップ用のジョブポッドは作成されません。この注釈は、`gitlab.toolbox.backups.cron.safeToEvict`パラメータを`true`に設定することで変更できます。これにより、ジョブの作成は許可されますが、削除されてバックアップが破損するリスクがあります。

{{< /alert >}}

このチャートでは、[Kubernetesスケジュール](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#schedule)で定義されているように、cronベースのバックアップを定期的に実行できるようにすることができます。

次のパラメータを設定する必要があります:

- `gitlab.toolbox.backups.cron.enabled`: cronベースのバックアップを有効にするには、trueに設定します
- `gitlab.toolbox.backups.cron.schedule`: Kubernetesスケジュールドキュメントに従って設定します
- `gitlab.toolbox.backups.cron.extraArgs`: 必要に応じて、[バックアップユーティリティ](https://gitlab.com/gitlab-org/build/CNG/blob/master/gitlab-toolbox/scripts/bin/backup-utility)に追加の引数を設定します（`--skip db`や`--s3tool awscli`など）。

## バックアップユーティリティの追加の引数 {#backup-utility-extra-arguments}

バックアップユーティリティは、いくつかの追加の引数を取ることができます。

### コンポーネントの除外 {#skipping-components}

`--skip`引数を使用してコンポーネントを除外します。有効なコンポーネント名は、[バックアップからの特定のデータの除外](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup)にあります。

各コンポーネントには、独自の`--skip`引数が必要です。例: 

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --skip db --skip lfs
```

### バックアップのみをクリーンアップする {#cleanup-backups-only}

新しいバックアップを作成せずに、バックアップのクリーンアップを実行します。

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --cleanup
```

### 使用するS3ツールを指定する {#specify-s3-tool-to-use}

`backup-utility`コマンドは、オブジェクトストレージに接続するために、デフォルトで`s3cmd`を使用します。`s3cmd`が他のS3ツールよりも信頼性が低い場合に、この追加の引数をオーバーライドする必要がある場合があります。

GitLabがS3バケットをCIジョブアーティファクトストレージとして使用し、デフォルトの`s3cmd`CLIツールが使用されている場合、`ERROR: S3 error: 404 (NoSuchKey): The specified key does not exist.`でバックアップジョブがクラッシュする[既知の問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)があります。`s3cmd`から`awscli`にスイッチすると、バックアップジョブを正常に実行できます。詳しくは、[issue 3338](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)をご覧ください。

使用するS3 CLIツールは、`s3cmd`または`awscli`のいずれかです。

 ```shell
 kubectl exec <Toolbox pod name> -it -- backup-utility --s3tool awscli
 ```

#### awscliでのMinIOの使用 {#using-minio-with-awscli}

`awscli`を使用するときに、オブジェクトストレージとしてMinIOを使用するには、次のパラメータを設定します:

```yaml
gitlab:
  toolbox:
    extraEnvFrom:
      AWS_ACCESS_KEY_ID:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: accesskey
      AWS_SECRET_ACCESS_KEY:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: secretkey
    extraEnv:
      AWS_DEFAULT_REGION: us-east-1 # MinIO default
    backups:
      cron:
        enabled: true
        schedule: "@daily"
        extraArgs: "--s3tool awscli --aws-s3-endpoint-url <MINIO-INGRESS-URL>"
```

{{< alert type="note" >}}

S3 CLIツール`s5cmd`のサポートは調査中です。進捗状況を追跡するには、[イシュー523](https://gitlab.com/gitlab-org/build/CNG/-/issues/523)を参照してください。

{{< /alert >}}

#### `awscli`によるデータ整合性保護 {#data-integrity-protection-with-awscli}

toolboxに含まれる`awscli`ツールの最近のバージョンでは、デフォルトでデータ整合性保護が適用されます。オブジェクトストレージサービスがこの機能をサポートしていない場合、この要件は次のようにして無効にできます:

```yaml
extraEnv:
  AWS_REQUEST_CHECKSUM_CALCULATION: WHEN_REQUIRED
```

この設定は、toolboxポッドの`extraEnv`またはグローバルの`extraEnv`のいずれかになります。

### サーバー側のリポジトリのバックアップ {#server-side-repository-backups}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)されました。

{{< /history >}}

大規模なリポジトリのバックアップをバックアップアーカイブに保存するのではなく、各リポジトリをホストするGitalyノードがバックアップを作成し、オブジェクトストレージにストリーミングできるように設定することが可能です。これにより、バックアップの作成と復元に必要なネットワークリソースを削減できます。

[サーバー側のリポジトリのバックアップを作成する](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#create-server-side-repository-backups)を参照してください。

### その他の引数 {#other-arguments}

使用可能な引数の完全なリストを表示するには、次のコマンドを実行します:

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --help
```

## シークレットをバックアップします。 {#back-up-the-secrets}

セキュリティ上の予防措置として、railsシークレットのコピーも保存する必要があります。これらはバックアップには含まれていません。データベースを含む完全なバックアップとシークレットのコピーは別々に保管することをお勧めします。

1. railsシークレットのオブジェクト名を検索します

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. railsシークレットのコピーを保存します

   ```shell
   kubectl get secrets <rails-secret-name> -o jsonpath="{.data['secrets\.yml']}" | base64 --decode > gitlab-secrets.yaml
   ```

1. `gitlab-secrets.yaml`を安全な場所に保管してください。これはバックアップを復元するために必要です。

## 追加情報 {#additional-information}

- [GitLabチャートのバックアップ / 復元の概要](_index.md)
- [GitLabインストールを復元する](restore.md)
